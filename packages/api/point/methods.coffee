Meteor.methods
  'Point.new': (document) ->
    # TODO: Move check into newUpvotable.
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless User.hasPermission User.PERMISSIONS.POINT_NEW

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

    if User.hasPermission User.PERMISSIONS.POINT_UPDATE
      permissionCheck = {}
    else if User.hasPermission User.PERMISSIONS.POINT_UPDATE_OWN
      permissionCheck =
        'author._id': user._id
    else
      permissionCheck =
        # TODO: Find a better "no-match" query.
        $and: [
          _id: 'a'
        ,
          _id: 'b'
        ]

    updatedAt = new Date()
    Point.documents.update _.extend(permissionCheck,
      _id: document._id
      $or: [
        body:
          $ne: document.body
      ,
        category:
          $ne: document.category
      ]
    ),
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
