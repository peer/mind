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
    Motion.documents.insert
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
      votingOpenedBy: null
      votingOpenedAt: null
      votingClosedBy: null
      votingClosedAt: null
      withdrawnBy: null
      withdrawnAt: null

  'Motion.openVoting': (motionId) ->
    check motionId, Match.DocumentId

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 401, "User not signed in." unless user

    # TODO: We should also allow moderators to open motions.
    openedAt = new Date()
    Motion.documents.update
      _id: motionId
      'author._id': user._id
      votingOpenedBy: null
      votingOpenedAt: null
      votingClosedBy: null
      votingClosedAt: null
      withdrawnBy: null
      withdrawnAt: null
    ,
      $set:
        votingOpenedBy: user.getReference()
        votingOpenedAt: openedAt

  'Motion.closeVoting': (motionId) ->
    check motionId, Match.DocumentId

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 401, "User not signed in." unless user

    # TODO: We should also allow moderators to close motions.
    closedAt = new Date()
    Motion.documents.update
      _id: motionId
      'author._id': user._id
      votingOpenedBy:
        $ne: null
      votingOpenedAt:
        $ne: null
      votingClosedBy: null
      votingClosedAt: null
      withdrawnBy: null
      withdrawnAt: null
    ,
      $set:
        votingClosedBy: user.getReference()
        votingClosedAt: closedAt

  'Motion.withdrawVoting': (motionId) ->
    check motionId, Match.DocumentId

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 401, "User not signed in." unless user

    # TODO: We should also allow moderators to withdraw motions.
    withdrawnAt = new Date()
    Motion.documents.update
      _id: motionId
      'author._id': user._id
      votingOpenedBy: null
      votingOpenedAt: null
      votingClosedBy: null
      votingClosedAt: null
      withdrawnBy: null
      withdrawnAt: null
    ,
      $set:
        withdrawnBy: user.getReference()
        withdrawnAt: withdrawnAt

  'Motion.vote': (document) ->
    check document,
      value: Match.OneOf 'abstain', 'default', Match.Where (value) ->
        _.isFinite(value) and -1 <= value <= 1
      motion:
        _id: Match.DocumentId

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 401, "User not signed in." unless user

    motion = Motion.documents.findOne document.motion._id,
      fields:
        _id: 1
        discussion: 1

    throw new Meteor.Error 400, "Invalid motion." unless motion

    createdAt = new Date()
    Vote.documents.update
      # We cannot directly specify the conditions because in upsert the conditions are appended
      # to the document when inserted. But if we use an operator, this does not happen.
      $and: [
        'author._id': user._id
      ,
        'motion._id': motion._id
      ]
    ,
      $setOnInsert:
        createdAt: createdAt
        author: user.getReference()
        motion:
          _id: motion._id
          discussion:
            _id: motion.discussion._id
      $set:
        updatedAt: createdAt
        value: document.value
      $push:
        valueChanges:
          updatedAt: createdAt
          value: document.value
    ,
      upsert: true
