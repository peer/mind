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

    if Meteor.isServer
      $root = cheerio.load(document.description).root()
    else
      $root = $('<div/>').append($.parseHTML(document.description))

    descriptionDisplay = Meeting.sanitizeForDisplay.sanitizeHTML document.description

    attachments = Meeting.extractAttachments document.description

    createdAt = new Date()
    documentId = Meeting.documents.insert
      createdAt: createdAt
      updatedAt: createdAt
      lastActivity: createdAt
      author: user.getReference()
      startAt: document.startAt
      endAt: document.endAt or null
      title: document.title
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
