Meteor.methods
  'Point.new': (document) ->
    share.newUpvotable Point, document,
      body: Match.NonEmptyString
      discussion:
        _id: Match.DocumentId
      category: Match.Enumeration String, Point.CATEGORY

  'Point.upvote': (pointId) ->
    share.upvoteUpvotable Point, pointId

  'Point.removeUpvote': (pointId) ->
    share.removeUpvoteUpvotable Point, pointId
