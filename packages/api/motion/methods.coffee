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

    document.body = Motion.sanitize.sanitizeHTML document.body

    if Meteor.isServer
      $root = cheerio.load(document.body).root()
    else
      $root = $('<div/>').append($.parseHTML(document.body))

    bodyText = $root.text()

    check bodyText, Match.OneOf Match.NonEmptyString, Match.Where ->
      $root.has('figure')

    bodyDisplay = Motion.sanitizeForDisplay.sanitizeHTML document.body

    attachments = Motion.extractAttachments document.body

    createdAt = new Date()
    documentId = Motion.documents.insert
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
      votingOpenedBy: null
      votingOpenedAt: null
      votingClosedBy: null
      votingClosedAt: null
      withdrawnBy: null
      withdrawnAt: null
      majority: null

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

  'Motion.update': (document) ->
    check document,
      _id: Match.DocumentId
      body: Match.NonEmptyString

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    document.body = Motion.sanitize.sanitizeHTML document.body

    if Meteor.isServer
      $root = cheerio.load(document.body).root()
    else
      $root = $('<div/>').append($.parseHTML(document.body))

    bodyText = $root.text()

    check bodyText, Match.OneOf Match.NonEmptyString, Match.Where ->
      $root.has('figure')

    bodyDisplay = Motion.sanitizeForDisplay.sanitizeHTML document.body

    attachments = Motion.extractAttachments document.body

    # TODO: We should also allow moderators to update motions.
    updatedAt = new Date()
    changed = Motion.documents.update
      _id: document._id
      'author._id': user._id
      votingOpenedBy: null
      votingOpenedAt: null
      votingClosedBy: null
      votingClosedAt: null
      withdrawnBy: null
      withdrawnAt: null
      majority: null
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

  'Motion.openVoting': (motionId, majority) ->
    check motionId, Match.DocumentId
    check majority, Match.Enumeration String, Motion.MAJORITY

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
      majority: null
    ,
      $set:
        votingOpenedBy: user.getReference()
        votingOpenedAt: openedAt
        majority: majority

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
      majority:
        $ne: null
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
      majority: null
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
        majority: 1

    throw new Meteor.Error 'not-found', "Motion '#{document.motion._id}' cannot be found." unless motion

    throw new Meteor.Error 'bad-request', "Motion '#{document.motion._id}' is not open." unless motion.isOpen()

    createdAt = new Date()
    try
      voteId = Vote.documents.insert
        createdAt: createdAt
        updatedAt: createdAt
        author: user.getReference()
        motion:
          _id: motion._id
          discussion:
            _id: motion.discussion._id
        value: document.value
        changes: [
          updatedAt: createdAt
          value: document.value
        ]
      assert voteId
      return 1
    catch error
      # If there is already a document (we have an index) then we have to update it instead.
      throw error unless /E11000 duplicate key error index:.*Votes\.\$author\._id_1_motion\._id_1/.test error.err

    Vote.documents.update
      'author._id': user._id
      'motion._id': motion._id
      value:
        $ne: document.value
    ,
      $set:
        updatedAt: createdAt
        value: document.value
      $push:
        changes:
          updatedAt: createdAt
          value: document.value
