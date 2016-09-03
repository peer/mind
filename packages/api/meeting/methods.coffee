Meteor.methods
  'Meeting.new': (document) ->
    check document,
      title: Match.NonEmptyString
      startAt: Date
      endAt: Match.OptionalOrNull Date
      description: String

    check document.startAt, Match.Where (value) ->
      _.isFinite value.valueOf()

    if document.endAt
      check document.endAt, Match.Where (value) ->
        _.isFinite value.valueOf()

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    throw new Meteor.Error 'unauthorized', "Unauthorized." unless User.hasPermission User.PERMISSIONS.MEETING_NEW

    document.description = Meeting.sanitize.sanitizeHTML document.description

    attachments = Meeting.extractAttachments document.description

    createdAt = new Date()
    documentId = Meeting.documents.insert
      createdAt: createdAt
      updatedAt: createdAt
      lastActivity: createdAt
      author: user.getReference()
      title: document.title
      startAt: document.startAt
      endAt: document.endAt or null
      description: document.description
      descriptionAttachments: ({_id} for _id in attachments)
      discussions: []
      changes: [
        updatedAt: createdAt
        author: user.getReference()
        title: document.title
        startAt: document.startAt
        endAt: document.endAt or null
        description: document.description
        discussions: []
      ]

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

  'Meeting.update': (document) ->
    check document,
      _id: Match.DocumentId
      title: Match.NonEmptyString
      startAt: Date
      endAt: Match.OptionalOrNull Date
      description: String

    check document.startAt, Match.Where (value) ->
      _.isFinite value.valueOf()

    if document.endAt
      check document.endAt, Match.Where (value) ->
        _.isFinite value.valueOf()

      throw new Meteor.Error 'invalid-request', "Start time is after end time." if document.startAt.valueOf() > document.endAt.valueOf()

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    document.description = Meeting.sanitize.sanitizeHTML document.description

    attachments = Meeting.extractAttachments document.description

    if User.hasPermission User.PERMISSIONS.MEETING_UPDATE
      permissionCheck = {}
    else if User.hasPermission User.PERMISSIONS.MEETING_UPDATE_OWN
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
    changed = Meeting.documents.update _.extend(permissionCheck,
      _id: document._id
      $or: [
        title:
          $ne: document.title
      ,
        startAt:
          $ne: document.startAt
      ,
        endAt:
          $ne: document.endAt
      ,
        description:
          $ne: document.description
      ]
    ),
      $set:
        updatedAt: updatedAt
        title: document.title
        startAt: document.startAt
        endAt: document.endAt or null
        description: document.description
        descriptionAttachments: ({_id} for _id in attachments)
      $push:
        changes:
          updatedAt: updatedAt
          author: user.getReference()
          title: document.title
          startAt: document.startAt
          endAt: document.endAt or null
          description: document.description

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

  'Meeting.toggleDiscussion': (meetingId, discussionId, selected) ->
    check meetingId, Match.DocumentId
    check discussionId, Match.DocumentId
    check selected, Boolean

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    # We could just leave to PeerDB to remove a reference to a non-existing
    # document but this would still dirty the changes field with an entry.
    return 0 unless Discussion.documents.exists discussionId

    meeting = Meeting.documents.findOne meetingId,
      fields:
        discussions: 1

    # We could leave it to the query below to not match anything,
    # but we can just short circuit here and immediately return.
    return 0 unless meeting

    if User.hasPermission User.PERMISSIONS.MEETING_UPDATE
      permissionCheck = {}
    else if User.hasPermission User.PERMISSIONS.MEETING_UPDATE_OWN
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
    if selected
      maxOrder = _.max _.pluck meeting.discussions, 'order'

      if _.isFinite maxOrder
        maxOrder += 1
      else
        maxOrder = 0

      Meeting.documents.update _.extend(permissionCheck,
        _id: meetingId
        discussions: meeting.discussions
        'discussions.discussion._id':
          $ne: discussionId
      ),
        $set:
          updatedAt: updatedAt
        $push:
          discussions:
            discussion:
              _id: discussionId
            order: maxOrder
            time: null
          changes:
            updatedAt: updatedAt
            author: user.getReference()
            discussions: (meeting.discussions or []).concat
              discussion:
                _id: discussionId
              order: maxOrder
              time: null

    else
      Meeting.documents.update _.extend(permissionCheck,
        _id: meetingId
        discussions: meeting.discussions
        'discussions.discussion._id': discussionId
      ),
        $set:
          updatedAt: updatedAt
        $pull:
          discussions:
            'discussion._id': discussionId
        $push:
          changes:
            updatedAt: updatedAt
            author: user.getReference()
            discussions: _.reject (meeting.discussions or []), (item) ->
              item.discussion._id is discussionId

  'Meeting.discussionOrder': (meetingId, discussionId, order) ->
    check meetingId, Match.DocumentId
    check discussionId, Match.DocumentId
    check order, Number

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    meeting = Meeting.documents.findOne meetingId,
      fields:
        discussions: 1

    # We could leave it to the query below to not match anything,
    # but we can just short circuit here and immediately return.
    return 0 unless meeting

    if User.hasPermission User.PERMISSIONS.MEETING_UPDATE
      permissionCheck = {}
    else if User.hasPermission User.PERMISSIONS.MEETING_UPDATE_OWN
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

    discussions = for discussion in meeting.discussions or []
      if discussion.discussion._id is discussionId
        _.extend {}, discussion,
          order: order
      else
        discussion

    updatedAt = new Date()
    Meeting.documents.update _.extend(permissionCheck,
      _id: meetingId
      discussions: meeting.discussions
      'discussions.discussion._id': discussionId
    ),
      $set:
        updatedAt: updatedAt
        'discussions.$.order': order
      $push:
        changes:
          updatedAt: updatedAt
          author: user.getReference()
          discussions: discussions

  'Meeting.discussionLength': (meetingId, discussionId, length) ->
    check meetingId, Match.DocumentId
    check discussionId, Match.DocumentId
    check length, Match.Where (x) ->
      check x, Match.Integer
      x >= 0

    # We convert zero to null.
    length = length or null

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    meeting = Meeting.documents.findOne meetingId,
      fields:
        discussions: 1

    # We could leave it to the query below to not match anything,
    # but we can just short circuit here and immediately return.
    return 0 unless meeting

    if User.hasPermission User.PERMISSIONS.MEETING_UPDATE
      permissionCheck = {}
    else if User.hasPermission User.PERMISSIONS.MEETING_UPDATE_OWN
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

    discussions = for discussion in meeting.discussions or []
      if discussion.discussion._id is discussionId
        _.extend {}, discussion,
          length: length
      else
        discussion

    updatedAt = new Date()
    Meeting.documents.update _.extend(permissionCheck,
      _id: meetingId
      discussions: meeting.discussions
      'discussions.discussion._id': discussionId
    ),
      $set:
        updatedAt: updatedAt
        'discussions.$.length': length
      $push:
        changes:
          updatedAt: updatedAt
          author: user.getReference()
          discussions: discussions
