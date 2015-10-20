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

  'Motion.openVoting': (motionId) ->
    check motionId, Match.DocumentId

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 401, "User not signed in." unless user

    # TODO: We should also allow moderators to open motions.
    openedAt = new Date()
    Motion.documents.update
      _id: motionId
      'author._id': user._id
      votingOpenedAt: null
      votingOpenedBy: null
      votingClosedAt: null
      votingClosedBy: null
    ,
      $set:
        votingOpenedAt: openedAt
        votingOpenedBy: user.getReference()

  'Motion.closeVoting': (motionId) ->
    check motionId, Match.DocumentId

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 401, "User not signed in." unless user

    # TODO: We should also allow moderators to close motions.
    closedAt = new Date()
    Motion.documents.update
      _id: motionId
      'author._id': user._id
      votingOpenedAt:
        $ne: null
      votingOpenedBy:
        $ne: null
      votingClosedAt: null
      votingClosedBy: null
    ,
      $set:
        votingClosedAt: closedAt
        votingClosedBy: user.getReference()
