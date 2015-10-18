new PublishEndpoint 'Discussion.list', ->
  Discussion.documents.find {},
    fields: Discussion.PUBLISH_FIELDS()

new PublishEndpoint 'Discussion.one', (documentId) ->
  check documentId, Match.DocumentId

  Discussion.documents.find documentId,
    fields: Discussion.PUBLISH_FIELDS()
