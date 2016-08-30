Meteor.methods
  'Motion.new': (document) ->
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless User.hasPermission User.PERMISSIONS.MOTION_NEW

    share.newUpvotable
      documentClass: Motion
      document: document
      match:
        body: Match.NonEmptyString
        discussion:
          _id: Match.DocumentId
      extend: (user, doc) ->
        _.extend doc,
          votingOpenedBy: null
          votingOpenedAt: null
          votingClosedBy: null
          votingClosedAt: null
          withdrawnBy: null
          withdrawnAt: null
          majority: null
          status: Motion.STATUS.DRAFT
      extraChecks: (user, discussion) ->
        throw new Meteor.Error 'invalid-request', "Discussion is not open." if discussion.status is Discussion.STATUS.DRAFT
        throw new Meteor.Error 'invalid-request', "Discussion is closed." if discussion.status in [Discussion.STATUS.CLOSED, Discussion.STATUS.PASSED]

  'Motion.upvote': (pointId) ->
    share.upvoteUpvotable Motion, pointId,
      votingOpenedBy: null
      votingOpenedAt: null
      votingClosedBy: null
      votingClosedAt: null
      withdrawnBy: null
      withdrawnAt: null
      majority: null
      status: Motion.STATUS.DRAFT

  'Motion.removeUpvote': (pointId) ->
    share.removeUpvoteUpvotable Motion, pointId,
      votingOpenedBy: null
      votingOpenedAt: null
      votingClosedBy: null
      votingClosedAt: null
      withdrawnBy: null
      withdrawnAt: null
      majority: null
      status: Motion.STATUS.DRAFT

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
      $root.has('figure').length

    bodyDisplay = Motion.sanitizeForDisplay.sanitizeHTML document.body

    attachments = Motion.extractAttachments document.body

    if User.hasPermission User.PERMISSIONS.MOTION_UPDATE
      permissionCheck = {}
    else if User.hasPermission User.PERMISSIONS.MOTION_UPDATE_OWN
      permissionCheck =
        'author._id': user._id
    else
      permissionCheck =
        # TODO: Find a better "no-match" query.
        $and: [
          _id: 'a'
        ,
          _id: 'b'
        ]

    updatedAt = new Date()
    changed = Motion.documents.update _.extend(permissionCheck,
      _id: document._id
      votingOpenedBy: null
      votingOpenedAt: null
      votingClosedBy: null
      votingClosedAt: null
      withdrawnBy: null
      withdrawnAt: null
      majority: null
      status: Motion.STATUS.DRAFT
      body:
        $ne: document.body
    ),
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

    if User.hasPermission User.PERMISSIONS.MOTION_OPEN_VOTING
      permissionCheck = {}
    else
      permissionCheck =
        # TODO: Find a better "no-match" query.
        $and: [
          _id: 'a'
        ,
          _id: 'b'
        ]

    openedAt = new Date()
    Motion.documents.update _.extend(permissionCheck,
      _id: motionId
      votingOpenedBy: null
      votingOpenedAt: null
      votingClosedBy: null
      votingClosedAt: null
      withdrawnBy: null
      withdrawnAt: null
      majority: null
      status: Motion.STATUS.DRAFT
    ),
      $set:
        votingOpenedBy: user.getReference()
        votingOpenedAt: openedAt
        majority: majority
        status: Motion.STATUS.OPEN

  'Motion.closeVoting': (motionId) ->
    check motionId, Match.DocumentId

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    if User.hasPermission User.PERMISSIONS.MOTION_CLOSE_VOTING
      permissionCheck = {}
    else
      permissionCheck =
        # TODO: Find a better "no-match" query.
        $and: [
          _id: 'a'
        ,
          _id: 'b'
        ]

    closedAt = new Date()
    Motion.documents.update _.extend(permissionCheck,
      _id: motionId
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
      status: Motion.STATUS.OPEN
    ),
      $set:
        votingClosedBy: user.getReference()
        votingClosedAt: closedAt
        status: Motion.STATUS.CLOSED

  'Motion.withdraw': (motionId) ->
    check motionId, Match.DocumentId

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    if User.hasPermission User.PERMISSIONS.MOTION_WITHDRAW
      permissionCheck = {}
    else if User.hasPermission User.PERMISSIONS.MOTION_WITHDRAW_OWN
      permissionCheck =
        'author._id': user._id
    else
      permissionCheck =
        # TODO: Find a better "no-match" query.
        $and: [
          _id: 'a'
        ,
          _id: 'b'
        ]

    withdrawnAt = new Date()
    Motion.documents.update _.extend(permissionCheck,
      _id: motionId
      votingOpenedBy: null
      votingOpenedAt: null
      votingClosedBy: null
      votingClosedAt: null
      withdrawnBy: null
      withdrawnAt: null
      majority: null
      status: Motion.STATUS.DRAFT
    ),
      $set:
        withdrawnBy: user.getReference()
        withdrawnAt: withdrawnAt
        status: Motion.STATUS.WITHDRAWN

  'Motion.vote': (document) ->
    check document,
      value: Match.OneOf Match.Enumeration(String, Vote.VALUE), Match.Where (value) ->
        _.isNumber(value) and -1 <= value <= 1
      motion:
        _id: Match.DocumentId

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    throw new Meteor.Error 'unauthorized', "Unauthorized." unless User.hasPermission User.PERMISSIONS.MOTION_VOTE

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

    # We use upsert with $setOnInsert to insert a vote document only
    # if it does not yet exist for the for this user and motion.
    {numberAffected, insertedId} = Vote.documents.upsert
      'author._id': user._id
      'motion._id': motion._id
    ,
      $setOnInsert:
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

    # One document modified (that is, inserted).
    return 1 if insertedId

    # Vote document already exists, then let us just update the vote, if the vote is different.
    # It could happen that document would be just removed between upsert and this update, but
    # we do not really support vote deletion, so this should not really be a concern. And even
    # if somebody is voting and deleting a vote at the same time, there is not really any reason
    # why update would not happen first, and then deletion, which would have the same effect
    # as first deletion and then update without match. The result is the same.
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
