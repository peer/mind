share.newUpvotable = (documentClass, document, richText, match, extend) ->
  check document, match

  extend ?= (user, doc) -> doc

  user = Meteor.user User.REFERENCE_FIELDS()
  throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

  discussion = Discussion.documents.findOne document.discussion._id,
    fields:
      _id: 1

  throw new Meteor.Error 'not-found', "Discussion '#{document.discussion._id}' cannot be found." unless discussion

  if richText
    document.body = documentClass.sanitize.sanitizeHTML document.body

    if Meteor.isServer
      $root = cheerio.load(document.body).root()
    else
      $root = $('<div/>').append($.parseHTML(document.body))

    bodyText = $root.text()

    check bodyText, Match.OneOf Match.NonEmptyString, Match.Where ->
      $root.has('figure')

    bodyDisplay = documentClass.sanitizeForDisplay.sanitizeHTML document.body

    attachments = documentClass.extractAttachments document.body

    richTextDocument =
      bodyDisplay: bodyDisplay
      bodyAttachments: ({_id} for _id in attachments)
  else
    richTextDocument = {}

  createdAt = new Date()
  documentId = documentClass.documents.insert extend user, _.extend richTextDocument,
    createdAt: createdAt
    updatedAt: createdAt
    lastActivity: createdAt
    author: user.getReference()
    discussion:
      _id: discussion._id
    body: document.body
    changes: [
      updatedAt: createdAt
      author: user.getReference()
      body: document.body
    ]
    upvotes: []
    upvotesCount: 0

  assert documentId

  if richText
    StorageFile.documents.update
      _id:
        $in: attachments
    ,
      $set:
        active: true
    ,
      multi: true

  documentId

share.upvoteUpvotable = (documentClass, documentId) ->
  check documentId, Match.DocumentId

  userId = Meteor.userId()
  throw new Meteor.Error 'unauthorized', "Unauthorized." unless userId

  createdAt = new Date()
  documentClass.documents.update
    _id: documentId
    # User has not upvoted already.
    'upvotes.author._id':
      $ne: userId
    # User cannot upvote their documents.
    'author._id':
      $ne: userId
  ,
    $addToSet:
      upvotes:
        createdAt: createdAt
        author:
          _id: userId
    $set:
      lastActivity: createdAt
    $inc:
      upvotesCount: 1

share.removeUpvoteUpvotable = (documentClass, documentId) ->
  check documentId, Match.DocumentId

  userId = Meteor.userId()
  throw new Meteor.Error 'unauthorized', "Unauthorized." unless userId

  lastActivity = new Date()
  documentClass.documents.update
    _id: documentId
    'upvotes.author._id': userId
  ,
    $pull:
      upvotes:
        'author._id': userId
    $set:
      lastActivity: lastActivity
    $inc:
      upvotesCount: -1
