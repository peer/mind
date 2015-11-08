Meteor.methods
  'Point.new': (document) ->
    # TODO: Only moderators should be able to make points.

    share.newUpvotable Point, document, false,
      body: Match.NonEmptyString
      discussion:
        _id: Match.DocumentId
      category: Match.Enumeration String, Point.CATEGORY
    ,
      (user, doc) ->
        doc.category = document.category
        doc.changes[0].category = document.category
        doc

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
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    # TODO: We should also allow moderators to update points.
    updatedAt = new Date()
    Point.documents.update
      _id: document._id
      'author._id': user._id
      $or: [
        body:
          $ne: document.body
      ,
        category:
          $ne: document.category
      ]
    ,
      $set:
        updatedAt: updatedAt
        body: document.body
        category: document.category
      $push:
        changes:
          updatedAt: updatedAt
          author: user.getReference()
          body: document.body
          category: document.category
