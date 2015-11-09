new PublishEndpoint 'Comment.list', (discussionId) ->
  check discussionId, Match.DocumentId

  Comment.documents.find
    'discussion._id': discussionId
  ,
    fields: Comment.PUBLISH_FIELDS()

new PublishEndpoint 'Comment.forEdit', (commentId) ->
  check commentId, Match.DocumentId

  Comment.documents.find
    _id: commentId
  ,
    fields:
      body: 1
