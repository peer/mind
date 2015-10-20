new PublishEndpoint 'Point.list', (discussionId) ->
  check discussionId, Match.DocumentId

  Point.documents.find
    'discussion._id': discussionId
  ,
    fields: Point.PUBLISH_FIELDS()
