Meteor.methods
  'Comment.new': (document) ->
    # TODO: Move check into newUpvotable.
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless User.hasPermission User.PERMISSIONS.COMMENT_NEW

    share.newUpvotable
      documentClass: Comment
      document: document
      match:
        body: Match.NonEmptyString
        discussion:
          _id: Match.DocumentId
      extraChecks: (user, discussion) ->
        throw new Meteor.Error 'invalid-request', "Discussion is not open." if discussion.status is Discussion.STATUS.DRAFT
        # In contrast with points and motions, we allow comments to be made for closed
        # discussions, but we display a message warning an user that they should consider
        # opening a new discussion instead. Only for drafts we do not allow commenting.

  'Comment.upvote': (commentId) ->
    share.upvoteUpvotable Comment, commentId

  'Comment.removeUpvote': (commentId) ->
    share.removeUpvoteUpvotable Comment, commentId

  'Comment.update': (document) ->
    check document,
      _id: Match.DocumentId
      body: Match.NonEmptyString

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    document.body = Comment.sanitize.sanitizeHTML document.body

    if Meteor.isServer
      $root = cheerio.load(document.body).root()
    else
      $root = $('<div/>').append($.parseHTML(document.body))

    bodyText = $root.text()

    check bodyText, Match.OneOf Match.NonEmptyString, Match.Where ->
      $root.has('figure').length

    bodyDisplay = Comment.sanitizeForDisplay.sanitizeHTML document.body

    attachments = Comment.extractAttachments document.body

    if User.hasPermission User.PERMISSIONS.COMMENT_UPDATE
      permissionCheck = {}
    else if User.hasPermission User.PERMISSIONS.COMMENT_UPDATE_OWN
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
    changed = Comment.documents.update _.extend(permissionCheck,
      _id: document._id
      body:
        $ne: document.body
    ),
      $set:
        updatedAt: updatedAt
        body: document.body
        bodyDisplay: bodyDisplay
        bodyAttachments: ({_id} for _id in attachments)
      $push:
        changes:
          updatedAt: updatedAt
          author: user.getReference()
          body: document.body

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
