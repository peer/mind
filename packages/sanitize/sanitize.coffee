class Sanitize
  constructor: (@allowedTags) ->

  sanitizeHTML: (body) ->
    $ = cheerio.load body,
      normalizeWhitespace: false
      xmlMode: false
      decodeEntities: true

    $cleanedContents = $.root().contents().map (i, element) =>
      @sanitizeElement $, $(element)

    $.root().empty().append($cleanedContents).html()

  # Returns sanitized element.
  sanitizeElement: ($, $element) ->
    assert.equal $element.length, 1

    if $element[0].type is 'tag'
      return @sanitizeTag $, $element

    else if $element[0].type is 'text'
      return @sanitizeText $, $element

    else
      return

  # Returns sanitized text element.
  sanitizeText: ($, $element) ->
    assert.equal $element[0].type, 'text'

    $element[0]

  # Returns sanitized href.
  sanitizeHref: ($, href) ->
    # If local absolute URL.
    if href[0] is '/'
      # We prepend root URL so that we can reuse the same normalization code.
      rootUrl = Meteor.absoluteUrl()
      rootUrl = rootUrl.substr 0, rootUrl.length - 1 # Remove trailing /.
      href = "#{rootUrl}#{href}"

    # If link is not valid and not HTTP or HTTPS, normalize returns null and attribute is then removed.
    # TODO: Do we want to allow mailto: links?
    href = UrlUtils.normalize href
    if href and rootUrl
      # Normalization should not change the root URL part.
      assert _.startsWith href, rootUrl
      # We remove root URL to return back to local absolute URL.
      href = href.substring rootUrl.length

    href

  # Modifies $element's attributes in-place.
  sanitizeAttributes: ($, $element, allowedAttributes) ->
    for attribute, value of $element[0].attribs when not allowedAttributes[attribute]
      $element.removeAttr attribute

    return

  # Returns sanitized contents of a tag element.
  sanitizeTagContents: ($, $element, allowedAttributes) ->
    @sanitizeAttributes $, $element, allowedAttributes

    # Special case for links.
    if $element[0].name is 'a' and 'href' of $element[0].attribs
      href = @sanitizeHref $, $element.attr('href')
      $element.attr 'href', href

    $cleanedContents = $element.contents().map (i, element) =>
      @sanitizeElement $, $(element)

    $cleanedContents

  # Returns sanitized tag element.
  sanitizeTag: ($, $element) ->
    assert.equal $element[0].type, 'tag'

    return unless $element[0].name of @allowedTags

    allowedAttributes = @allowedTags[$element[0].name]

    if _.isFunction allowedAttributes
      # Should return sanitized contents.
      $cleanedContents = allowedAttributes.call @, $, $element, @
    else
      $cleanedContents = @sanitizeTagContents $, $element, allowedAttributes

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

      if $el[0].type is 'text'
        # "$text" is a special tag name which specifies text.
        return unless '$text' of expectedElement

        return @sanitizeText $, $el

      else if $el[0].type is 'tag'
        return unless $el[0].name of expectedElement

        expectedElementDescription = expectedElement[$el[0].name]

        @sanitizeAttributes $, $el, expectedElementDescription.attributes

        if expectedElementDescription.children
          $children = @sanitizeTree $, $el, expectedElementDescription.children
          $el.empty().append $children
        else
          $el.empty()

        $el[0]

      else
        return

    $cleanedContents