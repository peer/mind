share.newUpvotable = ({documentClass, document, match, extend, extraChecks}) ->
  check document, match

  extend ?= (user, doc) -> doc
  extraChecks ?= (user, discussion) ->

  user = Meteor.user User.REFERENCE_FIELDS()
  throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

  discussion = Discussion.documents.findOne document.discussion._id

  throw new Meteor.Error 'not-found', "Discussion '#{document.discussion._id}' cannot be found." unless discussion

  extraChecks user, discussion

  document.body = documentClass.sanitize.sanitizeHTML document.body

  if Meteor.isServer
    $root = cheerio.load(document.body).root()
  else
    $root = $('<div/>').append($.parseHTML(document.body))

  bodyText = $root.text()

  check bodyText, Match.OneOf Match.NonEmptyString, Match.Where ->
    $root.has('figure').length

  bodyDisplay = documentClass.sanitizeForDisplay.sanitizeHTML document.body

  attachments = documentClass.extractAttachments document.body

  createdAt = new Date()
  documentId = documentClass.documents.insert extend user,
    createdAt: createdAt
    updatedAt: createdAt
    lastActivity: createdAt
    author: user.getReference()
    discussion:
      _id: discussion._id
    body: document.body
    bodyDisplay: bodyDisplay
    bodyAttachments: ({_id} for _id in attachments)
    changes: [
      updatedAt: createdAt
      author: user.getReference()
      body: document.body
    ]
    upvotes: []
    upvotesCount: 0

  assert documentId

  StorageFile.documents.update
    _id:
      $in: attachments
  ,
    $set:
      active: true
  ,
    multi: true

  documentId

share.upvoteUpvotable = (documentClass, documentId, permissionCheck) ->
  check documentId, Match.DocumentId

  permissionCheck ?= {}

  userId = Meteor.userId()
  throw new Meteor.Error 'unauthorized', "Unauthorized." unless userId

  throw new Meteor.Error 'unauthorized', "Unauthorized." unless User.hasPermission User.PERMISSIONS.UPVOTE

  createdAt = new Date()
  documentClass.documents.update _.extend(permissionCheck,
    _id: documentId
    # User has not upvoted already.
    'upvotes.author._id':
      $ne: userId
    # User cannot upvote their documents.
    'author._id':
      $ne: userId
  ),
    $addToSet:
      upvotes:
        createdAt: createdAt
        author:
          _id: userId
    $set:
      lastActivity: createdAt
    $inc:
      upvotesCount: 1

share.removeUpvoteUpvotable = (documentClass, documentId, permissionCheck) ->
  check documentId, Match.DocumentId

  permissionCheck ?= {}

  userId = Meteor.userId()
  throw new Meteor.Error 'unauthorized', "Unauthorized." unless userId

  # We allow anyone to remove their own upvote.

  lastActivity = new Date()
  documentClass.documents.update _.extend(permissionCheck,
    _id: documentId
    'upvotes.author._id': userId
  ),
    $pull:
      upvotes:
        'author._id': userId
    $set:
      lastActivity: lastActivity
    $inc:
      upvotesCount: -1
