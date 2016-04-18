Meteor.methods
  'Meeting.new': (document) ->
    check document,
      title: Match.NonEmptyString
      startAt: Date
      endAt: Match.OptionalOrNull Date
      description: Match.OptionalOrNull String

    check document.startAt, Match.Where (value) ->
      _.isFinite value.valueOf()

    if document.endAt
      check document.endAt, Match.Where (value) ->
        _.isFinite value.valueOf()

    document.description or= ''

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    throw new Meteor.Error 'unauthorized', "Unauthorized." unless User.hasPermission User.PERMISSIONS.MEETING_NEW

    document.description = Meeting.sanitize.sanitizeHTML document.description

    descriptionDisplay = Meeting.sanitizeForDisplay.sanitizeHTML document.description

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
      descriptionDisplay: descriptionDisplay
      descriptionAttachments: ({_id} for _id in attachments)
      discussions: []
      changes: [
        updatedAt: createdAt
        author: user.getReference()
        title: document.title
        startAt: document.startAt
        endAt: document.endAt or null
        description: document.description
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
      description: Match.OptionalOrNull String

    check document.startAt, Match.Where (value) ->
      _.isFinite value.valueOf()

    if document.endAt
      check document.endAt, Match.Where (value) ->
        _.isFinite value.valueOf()

    document.description or= ''

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    document.description = Meeting.sanitize.sanitizeHTML document.description

    descriptionDisplay = Meeting.sanitizeForDisplay.sanitizeHTML document.description

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
        descriptionDisplay: descriptionDisplay
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
