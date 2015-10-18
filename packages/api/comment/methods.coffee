Meteor.methods
  'Comment.new': (document) ->
    check document,
      body: Match.NonEmptyString
      discussion:
        _id: Match.DocumentId

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 401, "User not signed in." unless user

    discussion = Discussion.documents.findOne document.discussion._id,
      fields:
        _id: 1

    throw new Meteor.Error 400, "Invalid discussion." unless discussion

    createdAt = new Date()
    Comment.documents.insert
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

  'Comment.upvote': (commentId) ->
    check commentId, Match.DocumentId

    userId = Meteor.userId()
    throw new Meteor.Error 401, "User not signed in." unless userId

    createdAt = new Date()
    Comment.documents.update
      _id: commentId
      # User has not upvoted already.
      $not:
        'upvotes.author._id': userId
      # User cannot upvote their comments.
      'author._id':
        $ne: userId
    ,
      $addToSet:
        upvotes:
          createdAt: createdAt
          author:
            _id: userId
      lastActivity: createdAt
      upvotesCount:
        $inc: 1

  'Comment.removeUpvote': (commentId) ->
    check commentId, Match.DocumentId

    userId = Meteor.userId()
    throw new Meteor.Error 401, "User not signed in." unless userId

    lastActivity = new Date()
    Comment.documents.update
      _id: commentId
      'upvotes.author._id': userId
    ,
      $pull:
        upvotes:
          'author._id': userId
      lastActivity: lastActivity
      upvotesCount:
        $inc: -1
