Meteor.methods
  'Motion.new': (document) ->
    check document,
      body: Match.NonEmptyString
      discussion:
        _id: Match.DocumentId

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    discussion = Discussion.documents.findOne document.discussion._id,
      fields:
        _id: 1

    throw new Meteor.Error 'not-found', "Discussion '#{document.discussion._id}' cannot be found." unless discussion

    createdAt = new Date()
    Motion.documents.insert
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
      votingOpenedBy: null
      votingOpenedAt: null
      votingClosedBy: null
      votingClosedAt: null
      withdrawnBy: null
      withdrawnAt: null

  'Motion.update': (document) ->
    check document,
      _id: Match.DocumentId
      body: Match.NonEmptyString

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    # TODO: We should also allow moderators to update motions.
    updatedAt = new Date()
    Motion.documents.update
      _id: document._id
      'author._id': user._id
      votingOpenedBy: null
      votingOpenedAt: null
      votingClosedBy: null
      votingClosedAt: null
      withdrawnBy: null
      withdrawnAt: null
    ,
      $set:
        updatedAt: updatedAt
        body: document.body
      $push:
        changes:
          updatedAt: updatedAt
          author: user.getReference()
          body: document.body

  'Motion.openVoting': (motionId) ->
    check motionId, Match.DocumentId

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

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
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

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
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

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
      value: Match.OneOf Match.Enumeration(String, Vote.VALUE), Match.Where (value) ->
        _.isNumber(value) and -1 <= value <= 1
      motion:
        _id: Match.DocumentId

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    motion = Motion.documents.findOne document.motion._id,
      fields:
        _id: 1
        discussion: 1
        votingOpenedBy: 1
        votingOpenedAt: 1
        votingClosedBy: 1
        votingClosedAt: 1
        withdrawnBy: 1
        withdrawnAt: 1

    throw new Meteor.Error 'not-found', "Motion '#{document.motion._id}' cannot be found." unless motion

    throw new Meteor.Error 'bad-request', "Motion '#{document.motion._id}' is not open." unless motion.votingOpenedBy and motion.votingOpenedAt and not motion.votingClosedBy and not motion.votingClosedAt and not motion.withdrawnBy and not motion.withdrawnAt

    # TODO: Use a trigger and a task queue.
    Meteor.setTimeout ->
      computeTally document.motion._id
    , 10 # ms

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
        changes:
          updatedAt: createdAt
          value: document.value
    ,
      upsert: true

computeTally = (motionId) ->
  votes = Vote.documents.find('motion._id': motionId).map (vote, index, cursor) ->
    vote.value

  computedAt = new Date()

  # TODO: Get all users with voting role?
  populationSize = 10 # User.documents.count()

  result = VotingEngine.computeTally votes, populationSize

  Tally.documents.insert
    createdAt: computedAt
    motion:
      _id: motionId
    populationSize: populationSize
    votesCount: result.votesCount
    abstainsCount: result.abstainsCount
    inFavorVotesCount: result.inFavorVotesCount
    againstVotesCount: result.againstVotesCount
    confidenceLevel: result.confidenceLevel
    result: result.result
