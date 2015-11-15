Meteor.methods
  'Comment.new': (document) ->
    # TODO: Allow only those in "comment" role, which should be a sub-role of "member" role.
    # TODO: Move check into newUpvotable.
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless Roles.userIsInRole Meteor.userId(), 'member'

    share.newUpvotable Comment, document, true,
      body: Match.NonEmptyString
      discussion:
        _id: Match.DocumentId

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
      $root.has('figure')

    bodyDisplay = Comment.sanitizeForDisplay.sanitizeHTML document.body

    attachments = Comment.extractAttachments document.body

    # TODO: Should we also allow moderators to update comments?
    permissionCheck =
      'author._id': user._id

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
