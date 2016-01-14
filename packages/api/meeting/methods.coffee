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

    # TODO: Allow only to those in "meeting" role, which should be a sub-role of "moderator" role.
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless Roles.userIsInRole user._id, ['moderator']

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

    if Roles.userIsInRole user._id, 'moderator'
      permissionCheck = {}
    else
      permissionCheck =
        'author._id': user._id

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
