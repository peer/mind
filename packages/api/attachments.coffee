share.extractAttachments = (html) ->
  $ = cheerio.load html

  $documentIds = $('[data-trix-attachment]').map (i, attachment) =>
    JSON.parse($(attachment).attr('data-trix-attachment')).documentId or null

  # Convert cheerio array to a standard array.
  $documentIds.get()
