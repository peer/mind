Meteor.methods
  'Point.new': (document) ->
    # TODO: Only moderators should be able to make points.

    share.newUpvotable Point, document,
      body: Match.NonEmptyString
      discussion:
        _id: Match.DocumentId
      category: Match.Enumeration String, Point.CATEGORY

  'Point.upvote': (pointId) ->
    share.upvoteUpvotable Point, pointId

  'Point.removeUpvote': (pointId) ->
    share.removeUpvoteUpvotable Point, pointId
