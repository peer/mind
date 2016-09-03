Meteor.methods
  'Point.new': (document) ->
    # TODO: Move check into newUpvotable.
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless User.hasPermission User.PERMISSIONS.POINT_NEW

    share.newUpvotable
      documentClass: Point
      document: document
      match:
        body: Match.NonEmptyString
        discussion:
          _id: Match.DocumentId
        category: Match.Enumeration String, Point.CATEGORY
      extend: (user, doc) ->
        doc.category = document.category
        doc.changes[0].category = document.category
        doc
      extraChecks: (user, discussion) ->
        throw new Meteor.Error 'invalid-request', "Discussion is not open." if discussion.status is Discussion.STATUS.DRAFT
        throw new Meteor.Error 'invalid-request', "Discussion is closed." if discussion.status in [Discussion.STATUS.CLOSED, Discussion.STATUS.PASSED]

  'Point.upvote': (pointId) ->
    share.upvoteUpvotable Point, pointId,
      'discussion.status':
        $nin: [Discussion.STATUS.DRAFT, Discussion.STATUS.CLOSED, Discussion.STATUS.PASSED]

  'Point.removeUpvote': (pointId) ->
    share.removeUpvoteUpvotable Point, pointId,
      'discussion.status':
        $nin: [Discussion.STATUS.DRAFT, Discussion.STATUS.CLOSED, Discussion.STATUS.PASSED]

  # We allow changing points for closed discussions (one should be able to edit the record to correct it).
  # TODO: What to do if non-moderators will be able to create points themselves?
  'Point.update': (document) ->
    check document,
      _id: Match.DocumentId
      body: Match.NonEmptyString
      category: Match.Enumeration String, Point.CATEGORY

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    document.body = Point.sanitize.sanitizeHTML document.body

    if Meteor.isServer
      $root = cheerio.load(document.body).root()
    else
      $root = $('<div/>').append($.parseHTML(document.body))

    bodyText = $root.text()

    check bodyText, Match.OneOf Match.NonEmptyString, Match.Where ->
      $root.has('figure').length

    attachments = Point.extractAttachments document.body

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
    changed = Point.documents.update _.extend(permissionCheck,
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
        bodyAttachments: ({_id} for _id in attachments)
        category: document.category
      $push:
        changes:
          updatedAt: updatedAt
          author: user.getReference()
          body: document.body
          category: document.category

    if changed
      StorageFile.documents.update
        _id:
          $in: attachments
      ,
        $set:
          active: true
      ,
        multi: true

    changed
