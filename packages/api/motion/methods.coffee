Meteor.methods
  'Motion.new': (document) ->
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless User.hasPermission User.PERMISSIONS.MOTION_NEW

    share.newUpvotable
      connection: @connection
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
    share.upvoteUpvotable
      connection: @connection
      documentClass: Motion
      documentId: pointId
      permissionCheck:
        votingOpenedBy: null
        votingOpenedAt: null
        votingClosedBy: null
        votingClosedAt: null
        withdrawnBy: null
        withdrawnAt: null
        majority: null
        status: Motion.STATUS.DRAFT
        # Not really needed because motions can be made only on non-draft discussions, and while
        # a motion is in draft status, discussions cannot be closed anyway.
        'discussion.status':
          $nin: [Discussion.STATUS.DRAFT, Discussion.STATUS.CLOSED, Discussion.STATUS.PASSED]

  'Motion.removeUpvote': (pointId) ->
    share.removeUpvoteUpvotable
      connection: @connection
      documentClass: Motion
      documentId: pointId
      permissionCheck:
        votingOpenedBy: null
        votingOpenedAt: null
        votingClosedBy: null
        votingClosedAt: null
        withdrawnBy: null
        withdrawnAt: null
        majority: null
        status: Motion.STATUS.DRAFT
        # Not really needed because motions can be made only on non-draft discussions, and while
        # a motion is in draft status, discussions cannot be closed anyway.
        'discussion.status':
          $nin: [Discussion.STATUS.DRAFT, Discussion.STATUS.CLOSED, Discussion.STATUS.PASSED]

  # A discussion cannot be closed without all motions be closed (closed voting or withdrawn) first.
  # But we do not allow editing of motions after voting has been started or motion withdrawn,
  # so we effectively already do not allow editing of motions for closed discussions.
  # Similar reasoning holds for other methods for motions.
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

    attachments = Motion.extractAttachments document.body
    mentions = Motion.extractMentions document.body

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
        bodyAttachments: ({_id} for _id in attachments)
        bodyMentions: ({_id} for _id in mentions)
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
    changed = Motion.documents.update _.extend(permissionCheck,
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

    if changed and Meteor.isServer
      discussion = Discussion.documents.findOne
        'motions._id': motionId
      ,
        fields:
          title: 1
          followers: 1

      # This should not really happen.
      if discussion
        # We notify all followers.
        Activity.documents.insert
          timestamp: openedAt
          connection: @connection.id
          byUser: user.getReference()
          forUsers: _.uniq _.pluck(discussion.followers, 'user'), (u) -> u._id
          type: 'motionOpened'
          level: Activity.LEVEL.GENERAL
          data:
            discussion:
              _id: discussion._id
              title: discussion.title
            motion:
              _id: motionId

        # We notify all users who voted on any competing motion.
        # (Not really voted, but interacted in a way which gave them a Vote document.)
        competingVoters = _.pluck Vote.documents.find(
          'motion._id':
            $ne: motionId
          'motion.discussion._id': discussion._id
          # Author can be null if user was deleted in meantime.
          author:
            $ne: null
        ,
          fields:
            author: 1
        ).fetch(), 'author'

        Activity.documents.insert
          timestamp: openedAt
          connection: @connection.id
          byUser: user.getReference()
          forUsers: _.uniq competingVoters, (u) -> u._id
          type: 'competingMotionOpened'
          level: Activity.LEVEL.USER
          data:
            discussion:
              _id: discussion._id
              title: discussion.title
            motion:
              _id: motionId

    changed

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
    changed = Motion.documents.update _.extend(permissionCheck,
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

    if changed and Meteor.isServer
      discussion = Discussion.documents.findOne
        'motions._id': motionId
      ,
        fields:
          title: 1
          followers: 1

      # This should not really happen.
      if discussion
        # We notify all followers.
        Activity.documents.insert
          timestamp: closedAt
          connection: @connection.id
          byUser: user.getReference()
          forUsers: _.uniq _.pluck(discussion.followers, 'user'), (u) -> u._id
          type: 'motionClosed'
          level: Activity.LEVEL.GENERAL
          data:
            discussion:
              _id: discussion._id
              title: discussion.title
            motion:
              _id: motionId

        # We notify all users who voted on the motion.
        # (Not really voted, but interacted in a way which gave them a Vote document.)
        voters = _.pluck Vote.documents.find(
          'motion._id': motionId
          # Author can be null if user was deleted in meantime.
          author:
            $ne: null
        ,
          fields:
            author: 1
        ).fetch(), 'author'

        Activity.documents.insert
          timestamp: closedAt
          connection: @connection.id
          byUser: user.getReference()
          forUsers: _.uniq voters, (u) -> u._id
          type: 'votedMotionClosed'
          level: Activity.LEVEL.USER
          data:
            discussion:
              _id: discussion._id
              title: discussion.title
            motion:
              _id: motionId

    changed

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
    changed = Motion.documents.update _.extend(permissionCheck,
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

    if changed and Meteor.isServer
      discussion = Discussion.documents.findOne
        'motions._id': motionId
      ,
        fields:
          title: 1
          followers: 1

      # This should not really happen.
      if discussion
        Activity.documents.insert
          timestamp: withdrawnAt
          connection: @connection.id
          byUser: user.getReference()
          forUsers: _.uniq _.pluck(discussion.followers, 'user'), (u) -> u._id
          type: 'motionWithdrawn'
          level: Activity.LEVEL.GENERAL
          data:
            discussion:
              _id: discussion._id
              title: discussion.title
            motion:
              _id: motionId

    changed

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
