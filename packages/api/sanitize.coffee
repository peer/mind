sanitizeAttachment = ($, $element, sanitize) ->
  # If it is not attachment, allow only a with href attribute.
  unless $element.attr('data-trix-attachment')
    return sanitize.sanitizeTagContents $, $element,
      href: true

  @sanitizeAttributes $, $element,
    'href': true
    'data-trix-attachment': true
    'data-trix-content-type': true
    'data-trix-attributes': true

  # Invalid.
  return unless $element.attr('href')

  href = sanitize.sanitizeHref $, $element.attr('href')
  $element.attr 'href', href

  try
    JSON.parse $element.attr 'data-trix-attachment'
  catch error
    # Invalid.
    return

  try
    JSON.parse $element.attr 'data-trix-attributes' if $element.attr 'data-trix-attributes'
  catch error
    # Invalid.
    return

  sanitize.sanitizeTree $, $element,
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

share.sanitize = new Sanitize
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
