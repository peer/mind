share.extractAttachments = (html) ->
  if Meteor.isServer
    $ = cheerio
  else
    $ = jQuery

  $documentIds = $('[data-trix-attachment]', html).map (i, attachment) =>
    JSON.parse($(attachment).attr('data-trix-attachment')).documentId or null

  # Convert cheerio/jQuery array to a standard array.
  $documentIds.get()
