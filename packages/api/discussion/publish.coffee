new PublishEndpoint 'Discussion.list', ->
  Discussion.documents.find {},
    fields: Discussion.PUBLISH_FIELDS()

new PublishEndpoint 'Discussion.one', (discussionId) ->
  check discussionId, Match.DocumentId

  Discussion.documents.find discussionId,
    fields: Discussion.PUBLISH_FIELDS()
