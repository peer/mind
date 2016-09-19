Meteor.methods
  'Discussion.new': (document) ->
    check document,
      title: Match.NonEmptyString
      description: String

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    throw new Meteor.Error 'unauthorized', "Unauthorized." unless User.hasPermission User.PERMISSIONS.DISCUSSION_NEW

    document.description = Discussion.sanitize.sanitizeHTML document.description

    attachments = Discussion.extractAttachments document.description
    mentions = Discussion.extractMentions document.description

    createdAt = new Date()
    documentId = Discussion.documents.insert
      createdAt: createdAt
      updatedAt: createdAt
      lastActivity: createdAt
      author: user.getReference()
      title: document.title
      description: document.description
      descriptionAttachments: ({_id} for _id in attachments)
      descriptionMentions: ({_id} for _id in mentions)
      changes: [
        updatedAt: createdAt
        author: user.getReference()
        title: document.title
        description: document.description
      ]
      meetings: []
      discussionOpenedBy: user.getReference()
      discussionOpenedAt: createdAt
      discussionClosedBy: null
      discussionClosedAt: null
      passingMotions: []
      closingNote: ''
      motions: []
      comments: []
      points: []
      motionsCount: 0
      commentsCount: 0
      pointsCount: 0
      # TODO: For now we are always starting a discussion already in an open state.
      status: Discussion.STATUS.OPEN

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

  # We allow changing discussions even after they have been closed (one should be able to edit the record to correct it).
  # TODO: Should only moderators be able to do edit once a discussion is closed and not also the author of the discussion?
  # There is a question how many fields should be in each a changes entry. If only one field has changed, should only that
  # field be in a changes entry? But we cannot make a query which based on state at the time of the query populates
  # new changes entry to have only changed fields and not all fields we are potentially changing. On the other hand,
  # we could always have each change entry have only one changed field, and then add multiple changes entries for all
  # changes happened at once. Currently, code adds up to two entries per this method call, with multiple fields being
  # always added for each entry.
  'Discussion.update': (document, passingMotions, closingNote) ->
    check document,
      _id: Match.DocumentId
      title: Match.NonEmptyString
      description: String
    check passingMotions, [Match.DocumentId]
    check closingNote, String

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    document.description = Discussion.sanitize.sanitizeHTML document.description

    descriptionAttachments = Discussion.extractAttachments document.description
    descriptionMentions = Discussion.extractMentions document.description

    if User.hasPermission User.PERMISSIONS.DISCUSSION_UPDATE
      permissionCheck = {}
    else if User.hasPermission User.PERMISSIONS.DISCUSSION_UPDATE_OWN
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
    changedUpdate = Discussion.documents.update _.extend(permissionCheck,
      _id: document._id
      $or: [
        title:
          $ne: document.title
      ,
        description:
          $ne: document.description
      ]
    ),
      $set:
        updatedAt: updatedAt
        title: document.title
        description: document.description
        descriptionAttachments: ({_id} for _id in descriptionAttachments)
        descriptionMentions: ({_id} for _id in descriptionMentions)
      $push:
        changes:
          updatedAt: updatedAt
          author: user.getReference()
          title: document.title
          description: document.description

    if changedUpdate
      StorageFile.documents.update
        _id:
          $in: descriptionAttachments
      ,
        $set:
          active: true
      ,
        multi: true

    closingNote = Discussion.sanitize.sanitizeHTML closingNote

    closingNoteAttachments = Discussion.extractAttachments closingNote
    closingNoteMentions = Discussion.extractMentions closingNote

    # For closed discussions users with DISCUSSION_CLOSE permission can edit information about closing state.
    if User.hasPermission User.PERMISSIONS.DISCUSSION_CLOSE
      permissionCheck = {}
    else
      permissionCheck =
        # TODO: Find a better "no-match" query.
        $and: [
          _id: 'a'
        ,
          _id: 'b'
        ]

    query = [
      passingMotions:
        $not:
          $size: passingMotions.length
    ]

    for passingMotionId, i in passingMotions
      condition = {}
      condition["passingMotions.#{i}._id"] =
        $ne: passingMotionId
      query.push condition

    query.push
      closingNote:
        $ne: closingNote

    # See comments in the Discussion.close method.
    if Meteor.isServer and passingMotions.length
      allCondition =
        $all: ($elemMatch: {_id} for _id in passingMotions)
    else
      allCondition = {}

    changedClosing = Discussion.documents.update _.extend(permissionCheck,
      _id: document._id
      discussionOpenedAt:
        $ne: null
      discussionOpenedBy:
        $ne: null
      discussionClosedAt:
        $ne: null
      discussionClosedBy:
        $ne: null
      status:
        $in: [Discussion.STATUS.PASSED, Discussion.STATUS.CLOSED]
      motions: _.extend allCondition,
        $not:
          $elemMatch:
            status:
              $nin: [Motion.STATUS.CLOSED, Motion.STATUS.WITHDRAWN]
      $or: query
    ),
      $set:
        updatedAt: updatedAt
        passingMotions: ({_id} for _id in passingMotions)
        closingNote: closingNote
        closingNoteAttachments: ({_id} for _id in closingNoteAttachments)
        closingNoteMentions: ({_id} for _id in closingNoteMentions)
        status: if passingMotions.length then Discussion.STATUS.PASSED else Discussion.STATUS.CLOSED
      $push:
        changes:
          updatedAt: updatedAt
          author: user.getReference()
          passingMotions: ({_id} for _id in passingMotions)
          closingNote: closingNote

    if changedClosing
      StorageFile.documents.update
        _id:
          $in: closingNoteAttachments
      ,
        $set:
          active: true
      ,
        multi: true

    [changedUpdate, changedClosing]

  # TODO: Implement Discussion.open. For now we open discussions by default.

  'Discussion.close': (discussionID, passingMotions, closingNote) ->
    check discussionID, Match.DocumentId
    check passingMotions, [Match.DocumentId]
    check closingNote, String

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    closingNote = Discussion.sanitize.sanitizeHTML closingNote

    attachments = Discussion.extractAttachments closingNote
    mentions = Discussion.extractMentions closingNote

    if User.hasPermission User.PERMISSIONS.DISCUSSION_CLOSE
      permissionCheck = {}
    else
      permissionCheck =
        # TODO: Find a better "no-match" query.
        $and: [
          _id: 'a'
        ,
          _id: 'b'
        ]

    # This is a special case. If passingMotions is empty, $all would not match anything
    # if we use $all: []. Moreover, Minimongo does not support $all/$elemMatch queries.
    if Meteor.isServer and passingMotions.length
      # We make sure that all motions passed through passingMotions are really
      # associated with this discussion.
      allCondition =
        $all: ($elemMatch: {_id} for _id in passingMotions)
    else
      allCondition = {}

    closedAt = new Date()
    changed = Discussion.documents.update _.extend(permissionCheck,
      _id: discussionID
      discussionOpenedAt:
        $ne: null
      discussionOpenedBy:
        $ne: null
      discussionClosedAt: null
      discussionClosedBy: null
      passingMotions:
        $in: [null, []]
      # All motions should have voting closed or motions should be withdrawn.
      # This also assures that all the motions provided passingMotions are of
      # the right status (there might be a race condition here though).
      status: Discussion.STATUS.OPEN
      motions: _.extend allCondition,
        # Additionally, we check that all associated motions are or closed or
        # withdrawn. This is also a potential race condition, but hopefully
        # at least one of this or the status check above will work.
        $not:
          $elemMatch:
            status:
              $nin: [Motion.STATUS.CLOSED, Motion.STATUS.WITHDRAWN]
    ),
      $set:
        updatedAt: closedAt
        discussionClosedBy: user.getReference()
        discussionClosedAt: closedAt
        passingMotions: ({_id} for _id in passingMotions)
        closingNote: closingNote
        closingNoteAttachments: ({_id} for _id in attachments)
        closingNoteMentions: ({_id} for _id in mentions)
        status: if passingMotions.length then Discussion.STATUS.PASSED else Discussion.STATUS.CLOSED
      $push:
        changes:
          updatedAt: closedAt
          author: user.getReference()
          passingMotions: ({_id} for _id in passingMotions)
          closingNote: closingNote

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
