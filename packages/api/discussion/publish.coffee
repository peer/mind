new PublishEndpoint 'Discussion.list', ->
  Discussion.documents.find {},
    fields: Discussion.PUBLISH_FIELDS()

new PublishEndpoint 'Discussion.one', (documentId) ->
  check documentId, Match.DocumentId

  Discussion.documents.find documentId,
    fields: Discussion.PUBLISH_FIELDS()

new PublishEndpoint 'Discussion.forEdit', (documentId) ->
  check documentId, Match.DocumentId

  # TODO: Allow only for those who can edit the discussion?

  Discussion.documents.find
    _id: documentId
  ,
    fields:
      description: 1
