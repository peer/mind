sanitizeAttachmentTree = ($, $element, sanitize) ->
  sanitize.sanitizeTree $, $element, [
    figure:
      attributes:
        class: true
      children:
        img:
          attributes:
            src: true
            width: true
            height: true
        figcaption:
          attributes:
            class: true
          children:
            $text: true
            span:
              attributes:
                class: true
              children:
                $text: true
  ]

# Used for mentions attachments.
sanitizeContentAttachmentTree = ($, $element, sanitize) ->
  sanitize.sanitizeTree $, $element,
    a:
      attributes:
        href: true
        class: true
      children:
        $text: true

# Should sanitize the tag and return its sanitized contents.
# TODO: We should maybe simply re-render the whole attachment based on JSON data.
#       So users cannot submit contradictory HTML and a different JSON.
#       For example, to display image of one attachment, while JSON is pointing to the other.
#       Or make a link to the file point somewhere else, but display a different image for it.
sanitizeAttachment = ($, $element, sanitize) ->
  # If it is not attachment, allow only a with href attribute.
  unless $element.attr('data-trix-attachment')
    return sanitize.sanitizeTagAndContents $, $element,
      href: true

  @sanitizeAttributes $, $element,
    'href': true
    'data-trix-attachment': true
    'data-trix-content-type': true

  # Invalid.
  return unless $element.attr('href')

  href = sanitize.sanitizeHref $, $element.attr('href')
  $element.attr 'href', href

  try
    JSON.parse $element.attr 'data-trix-attachment'
  catch error
    # Invalid.
    return

  sanitizeAttachmentTree $, $element, sanitize

# Used for mentions attachments.
# TODO: We should maybe simply re-render the whole attachment based on JSON data.
#       So users cannot submit contradictory HTML and a different JSON.
#       For example, to display an username of one user, while JSON is pointing to the other.
#       Or make a link to one user account, but display a different username for it.
sanitizeContentAttachment = ($, $element, sanitize) ->
  # Do not allow if it is not content attachment.
  return unless $element.attr('data-trix-attachment')

  @sanitizeAttributes $, $element,
    'class': true
    'data-trix-attachment': true

  try
    JSON.parse $element.attr 'data-trix-attachment'
  catch error
    # Invalid.
    return

  sanitizeContentAttachmentTree $, $element, sanitize

class share.BaseDocument extends Document
  @Meta
    abstract: true

  @sanitize: new Sanitize
    div: {}
    br: {}

    strong: {}
    em: {}
    del: {}
    a: sanitizeAttachment
    blockquote: {}
    pre: {}
    ul: {}
    li: {}
    ol: {}

    # Used for mentions attachments.
    figure: sanitizeContentAttachment

  @extractAttachments: (html) ->
    if Meteor.isServer
      $ = cheerio
    else
      $ = jQuery

    $documentIds = $('[data-trix-attachment]', html).map (i, attachment) =>
      data = JSON.parse $(attachment).attr('data-trix-attachment')

      # Returning null skips this attachment.
      return null if data.type is 'mention'

      data.documentId or null

    # Convert cheerio/jQuery array to a standard array.
    _.unique $documentIds.get()

  @extractMentions: (html) ->
    if Meteor.isServer
      $ = cheerio
    else
      $ = jQuery

    $documentIds = $('[data-trix-attachment]', html).map (i, attachment) =>
      data = JSON.parse $(attachment).attr('data-trix-attachment')

      # Returning null skips this attachment.
      return null unless data.type is 'mention'

      data.documentId or null

    # Convert cheerio/jQuery array to a standard array.
    _.unique $documentIds.get()

  # Verbose name is used when representing the class in a non-technical
  # setting. The convention is not to capitalize the first letter of
  # the verboseName. We capitalize the first letter where we need to.
  @verboseName: ->
    # Convert TitleCase into Title Case, and make lower case.
    @Meta._name.replace(/([a-z0-9])([A-Z])/g, '$1 $2').toLowerCase()

  @verboseNamePlural: ->
    "#{@verboseName()}s"

  @verboseNameWithCount: (quantity) ->
    quantity = 0 unless quantity
    return "1 #{@verboseName()}" if quantity is 1
    "#{quantity} #{@verboseNamePlural()}"

  verboseName: ->
    @constructor.verboseName()

  verboseNamePlural: ->
    @constructor.verboseNamePlural()

  verboseNameWithCount: (quantity) ->
    @constructor.verboseNameWithCount()

  @methodPrefix: ->
    @Meta._name

  methodPrefix: ->
    @constructor.methodPrefix()

  @PUBLISH_FIELDS: ->
    {}
