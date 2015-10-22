share.newUpvotable = (documentClass, document, match, extend) ->
  check document, match

  extend ?= (user, doc) -> doc

  user = Meteor.user User.REFERENCE_FIELDS()
  throw new Meteor.Error 401, "User not signed in." unless user

  discussion = Discussion.documents.findOne document.discussion._id,
    fields:
      _id: 1

  throw new Meteor.Error 400, "Invalid discussion." unless discussion

  createdAt = new Date()
  documentClass.documents.insert extend user,
    createdAt: createdAt
    updatedAt: createdAt
    lastActivity: createdAt
    author: user.getReference()
    discussion:
      _id: discussion._id
    body: document.body
    bodyChanges: [
      updatedAt: createdAt
      author: user.getReference()
      body: document.body
    ]
    upvotes: []
    upvotesCount: 0

share.upvoteUpvotable = (documentClass, documentId) ->
  check documentId, Match.DocumentId

  userId = Meteor.userId()
  throw new Meteor.Error 401, "User not signed in." unless userId

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
  throw new Meteor.Error 401, "User not signed in." unless userId

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
