Meteor.methods
  'Motion.new': (document) ->
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
    Motion.documents.insert _.extend document,
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
      votingOpened: null
      votingClosed: null

  'Motion.vote': (motionId) ->
