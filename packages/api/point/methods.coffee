Meteor.methods
  'Point.new': (document) ->
    # TODO: Allow only those in "point" role, which should be a sub-role of "moderator" role.
    # TODO: Move check into newUpvotable.
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless Roles.userIsInRole Meteor.userId(), 'moderator'

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

    # Any moderator can update any point. Users cannot update their points even if there were moderators at some point.
    if Roles.userIsInRole user._id, 'moderator'
      permissionCheck = {}
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
