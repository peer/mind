share.newUpvotable = ({connection, documentClass, document, match, extend, extraChecks}) ->
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

  attachments = documentClass.extractAttachments document.body
  mentions = documentClass.extractMentions document.body

  createdAt = new Date()
  documentId = documentClass.documents.insert extend user,
    createdAt: createdAt
    updatedAt: createdAt
    lastActivity: createdAt
    author: user.getReference()
    discussion:
      _id: discussion._id
    body: document.body
    bodyAttachments: ({_id} for _id in attachments)
    bodyMentions: ({_id} for _id in mentions)
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

  data =
    discussion:
      _id: discussion._id
  data["#{documentClass.Meta._name.toLowerCase()}"] =
    _id: documentId

  if Meteor.isServer
    Activity.documents.insert
      timestamp: createdAt
      connection: connection.id
      byUser: user.getReference()
      forUsers: _.uniq _.pluck(discussion.followers, 'user'), (u) -> u._id
      type: "#{documentClass.Meta._name.toLowerCase()}Created"
      level: Activity.LEVEL.GENERAL
      data: data

    Discussion.documents.update
      _id: discussion._id
      'followers.user._id':
        $ne: user._id
    ,
      $addToSet:
        followers:
          user:
            _id: user._id
          reason: Discussion.REASON.PARTICIPATED

  documentId

share.upvoteUpvotable = ({connection, documentClass, documentId, permissionCheck}) ->
  check documentId, Match.DocumentId

  permissionCheck ?= {}

  user = Meteor.user User.REFERENCE_FIELDS()
  throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

  throw new Meteor.Error 'unauthorized', "Unauthorized." unless User.hasPermission User.PERMISSIONS.UPVOTE

  document = documentClass.documents.findOne documentId

  throw new Meteor.Error 'not-found', "#{documentClass.Meta._name} '#{documentId}' cannot be found." unless document

  createdAt = new Date()
  changed = documentClass.documents.update _.extend(permissionCheck,
    _id: document._id
    # User has not upvoted already.
    'upvotes.author._id':
      $ne: user._id
    # User cannot upvote their documents.
    'author._id':
      $ne: user._id
  ),
    $addToSet:
      upvotes:
        createdAt: createdAt
        author:
          _id: user._id
    $set:
      lastActivity: createdAt
    $inc:
      upvotesCount: 1

  if changed and Meteor.isServer
    data =
      discussion:
        _id: document.discussion._id
    data["#{documentClass.Meta._name.toLowerCase()}"] =
      _id: documentId

    Activity.documents.insert
      timestamp: createdAt
      connection: connection.id
      byUser: user.getReference()
      forUsers: [
        _id: document.author._id
      ]
      type: "#{documentClass.Meta._name.toLowerCase()}Upvoted"
      level: Activity.LEVEL.USER
      data: data

  changed

share.removeUpvoteUpvotable = ({connection, documentClass, documentId, permissionCheck}) ->
  check documentId, Match.DocumentId

  permissionCheck ?= {}

  userId = Meteor.userId()
  throw new Meteor.Error 'unauthorized', "Unauthorized." unless userId

  # We allow anyone to remove their own upvote.

  lastActivity = new Date()
  changed = documentClass.documents.update _.extend(permissionCheck,
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

  if changed
    # We just remove prior activity document when upvote is removed.
    Activity.documents.remove
      'byUser._id': userId
      type: 'documentUpvoted'
      level: Activity.LEVEL.USER
      "data.#{documentClass.Meta._name.toLowerCase()}._id": documentId

  changed
