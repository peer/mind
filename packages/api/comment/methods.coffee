Meteor.methods
  'Comment.new': (document) ->
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

    attachments = Comment.extractAttachments document.body

    bodyDisplay = Comment.sanitizeForDisplay.sanitizeHTML document.body

    # TODO: Should we also allow moderators to update comments?
    updatedAt = new Date()
    changed = Comment.documents.update
      _id: document._id
      'author._id': user._id
      body:
        $ne: document.body
    ,
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
