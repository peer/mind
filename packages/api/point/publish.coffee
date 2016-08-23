new PublishEndpoint 'Point.list', (discussionId) ->
  check discussionId, Match.DocumentId

  Point.documents.find
    'discussion._id': discussionId
  ,
    fields: Point.PUBLISH_FIELDS()

new PublishEndpoint 'Point.forEdit', (pointId) ->
  check pointId, Match.DocumentId

  # TODO: Allow only for those who can edit the point?

  Point.documents.find
    _id: pointId
  ,
    fields:
      body: 1
