new PublishEndpoint 'Comment.list', (discussionId) ->
  check discussionId, Match.DocumentId

  Comment.documents.find
    'discussion._id': discussionId
  ,
    fields: Comment.PUBLISH_FIELDS()
