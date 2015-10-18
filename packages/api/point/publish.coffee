new PublishEndpoint 'Point.list', (discussionId) ->
  Point.documents.find
    'discussion._id': discussionId
  ,
    fields: Point.PUBLISH_FIELDS()
