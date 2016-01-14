new PublishEndpoint 'Discussion.list', ->
  Discussion.documents.find {},
    fields: Discussion.PUBLISH_FIELDS()

new PublishEndpoint 'Discussion.one', (discussionId) ->
  check discussionId, Match.DocumentId

  Discussion.documents.find discussionId,
    fields: Discussion.PUBLISH_FIELDS()

new PublishEndpoint 'Discussion.forEdit', (discussionId) ->
  check discussionId, Match.DocumentId

  # TODO: Allow only for those who can edit the discussion?

  Discussion.documents.find
    _id: discussionId
  ,
    fields:
      description: 1
