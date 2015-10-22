Meteor.methods
  'Point.new': (document) ->
    # TODO: Only moderators should be able to make points.

    share.newUpvotable Point, document,
      body: Match.NonEmptyString
      discussion:
        _id: Match.DocumentId
      category: Match.Enumeration String, Point.CATEGORY
    ,
      (user, doc) ->
        _.extend doc,
          category: document.category
          categoryChanges: [
            updatedAt: doc.createdAt
            author: user.getReference()
            category: document.category
          ]

  'Point.upvote': (pointId) ->
    share.upvoteUpvotable Point, pointId

  'Point.removeUpvote': (pointId) ->
    share.removeUpvoteUpvotable Point, pointId

  'Point.update': (document) ->
    check document,
      _id: Match.DocumentId
      body: Match.NonEmptyString
      category: Match.Enumeration String, Point.CATEGORY

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 401, "User not signed in." unless user

    # TODO: We should also allow moderators to update points.
    updatedAt = new Date()
    Point.documents.update
      _id: document._id
      'author._id': user._id
    ,
      $set:
        updatedAt: updatedAt
        body: document.body
        category: document.category
      $push:
        bodyChanges:
          updatedAt: updatedAt
          author: user.getReference()
          body: document.body
        categoryChanges:
          updatedAt: updatedAt
          author: user.getReference()
          category: document.category
