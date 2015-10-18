new PublishEndpoint 'Comment.list', (discussionId) ->
  Comment.documents.find
    'discussion._id': discussionId
  ,
    fields: Comment.PUBLISH_FIELDS()
