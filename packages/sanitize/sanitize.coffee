if Meteor.isClient
  # In Safari 8 documents created via document.implementation.createHTMLDocument
  # collapse sibling forms: the second one becomes a child of the first one.
  # Because of that, this security measure has to be disabled in Safari 8.
  # See: https://bugs.webkit.org/show_bug.cgi?id=137337
  # Taken from jQuery (backporting).
  createHTMLDocumentSupported = do ->
    return jQuery.support.createHTMLDocument if 'createHTMLDocument' of jQuery.support

    return false unless document.implementation?.createHTMLDocument

    body = document.implementation.createHTMLDocument('').body
    body.innerHTML = '<form></form><form></form>'
    body.childNodes.length is 2

class Sanitize
  constructor: (@allowedTags) ->

  sanitizeHTML: (body) ->
    if Meteor.isServer
      @_sanitizeHTMLServer body
    else
      @_sanitizeHTMLClient body

  _sanitizeHTMLServer: (body) ->
    $ = cheerio.load body,
      normalizeWhitespace: false
      xmlMode: false
      decodeEntities: true

    @_sanitizeHTMLRoot $, $.root()

  _sanitizeHTMLClient: (body) ->
    if createHTMLDocumentSupported
      context = document.implementation.createHTMLDocument ''

      # Set the base href for the created document so any parsed
      # elements with URLs are based on the document's URL.
      # See: https://github.com/jquery/jquery/issues/2965
      base = context.createElement 'base'
      base.href = document.location.href
      context.head.appendChild base
    else
      context = document

    # Create a version of jQuery which uses our context by default.
    # This makes it safer later on if we call $(unsafeTag) to not
    # trigger any side-effects by attaching it to main document.
    $ = (selector, innerContext) ->
      jQuery selector, innerContext or context

    for own key, value of jQuery
      $[key] = value

    $.prototype = $.fn

    # This tag is created inside context.
    $root = $('<div/>')

    # We want script tags to be parsed because we do want to allow one
    # to not sanitize them, if they decide so.
    $root.append $.parseHTML(body, context, true)

    @_sanitizeHTMLRoot $, $root

  _sanitizeHTMLRoot: ($, $root) ->
    $cleanedContents = $root.contents().map (i, element) =>
      @sanitizeElement $, $(element)

    $root.empty().append($cleanedContents).html()

  isTag: (element) ->
    if Meteor.isServer
      element.type is 'tag'
    else
      element.nodeType is 1

  isText: (element) ->
    if Meteor.isServer
      element.type is 'text'
    else
      element.nodeType is 3

  nodeName: (element) ->
    if Meteor.isServer
      element.name
    else
      element.nodeName.toLowerCase()

  attributes: (element) ->
    if Meteor.isServer
      element.attribs
    else
      attribs = {}
      for attribute in element.attributes
        attribs[attribute.nodeName] = attribute.nodeValue
      attribs

  # Returns sanitized element.
  sanitizeElement: ($, $element) ->
    assert.equal $element.length, 1

    if @isTag $element[0]
      return @sanitizeTag $, $element

    else if @isText $element[0]
      return @sanitizeText $, $element

    else
      return

  # Returns sanitized text element.
  sanitizeText: ($, $element) ->
    assert @isText $element[0]

    $element[0]

  # Returns sanitized href.
  sanitizeHref: ($, href) ->
    rootUrl = Meteor.absoluteUrl()
    # Remove trailing /.
    rootUrl = rootUrl.substr 0, rootUrl.length - 1

    # If local absolute URL.
    if href[0] is '/'
      # We prepend root URL so that we can reuse the same normalization code.
      href = "#{rootUrl}#{href}"

    # If link is not valid and not HTTP or HTTPS, normalize returns null and attribute is then removed.
    # TODO: Do we want to allow mailto: links?
    href = UrlUtils.normalize href
    if href
      # If URL is an absolute URL to the app (or because we prepended the root, or because
      # it was provided already like that). Normalization should not change the root URL part.
      if _.startsWith href, rootUrl
        # We remove root URL to return back to local absolute URL.
        href = href.substring rootUrl.length

    href

  # Modifies $element's attributes in-place.
  sanitizeAttributes: ($, $element, allowedAttributes) ->
    for attribute, value of @attributes($element[0]) when not allowedAttributes[attribute]
      $element.removeAttr attribute

    return

  # Sanitized the tag element and returns its sanitized contents.
  sanitizeTagAndContents: ($, $element, allowedAttributes) ->
    @sanitizeAttributes $, $element, allowedAttributes

    # Special case for links.
    if @nodeName($element[0]) is 'a' and 'href' of @attributes($element[0])
      href = @sanitizeHref $, $element.attr('href')
      $element.attr 'href', href

    $cleanedContents = $element.contents().map (i, element) =>
      @sanitizeElement $, $(element)

    $cleanedContents

  # Returns sanitized tag element.
  sanitizeTag: ($, $element) ->
    assert @isTag $element[0]

    nodeName = @nodeName $element[0]

    return unless nodeName of @allowedTags

    allowedAttributes = @allowedTags[nodeName]

    if _.isFunction allowedAttributes
      # Should sanitize the tag and return its sanitized contents.
      $cleanedContents = allowedAttributes.call @, $, $element, @
    else
      $cleanedContents = @sanitizeTagAndContents $, $element, allowedAttributes

    $element.empty().append $cleanedContents

    $element[0]

  # Returns sanitized contents of a tag element according to an expected tree.
  sanitizeTree: ($, $element, expectedTree) ->
    $cleanedContents = $element.contents().map (i, el) =>
      $el = $(el)

      if _.isArray expectedTree
        # If it is an array, order is specified and an exact tag must match
        return unless 0 <= i < expectedTree.length

        expectedElement = expectedTree[i]
      else
        # Otherwise any of tags specified can match.
        expectedElement = expectedTree

      if @isText $el[0]
        # "$text" is a special tag name which specifies text.
        return unless expectedElement.$text

        return @sanitizeText $, $el

      else if @isTag $el[0]
        nodeName = @nodeName $el[0]

        return unless nodeName of expectedElement

        expectedElementDescription = expectedElement[nodeName]

        if _.isFunction expectedElementDescription
          # Should sanitize the tag and return its sanitized contents.
          $children = expectedElementDescription.call @, $, $el, @
        else
          @sanitizeAttributes $, $el, (expectedElementDescription.attributes or {})

          # Special case for links.
          if nodeName is 'a' and 'href' of @attributes($element[0])
            href = @sanitizeHref $, $el.attr('href')
            $el.attr 'href', href

          if expectedElementDescription.children
            $children = @sanitizeTree $, $el, expectedElementDescription.children
          else
            $children = $()

        $el.empty().append $children

        $el[0]

      else
        return

    $cleanedContents