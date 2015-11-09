Meteor.methods
  'Discussion.new': (document) ->
    check document,
      title: Match.NonEmptyString
      description: Match.NonEmptyString

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    attachments = []

    document.description = Discussion.sanitize.sanitizeHTML document.description

    if Meteor.isServer
      $root = cheerio.load(document.description).root()
    else
      $root = $('<div/>').append($.parseHTML(document.description))

    descriptionText = $root.text()

    check descriptionText, Match.OneOf Match.NonEmptyString, Match.Where ->
      $root.has('figure')

    attachments = Discussion.extractAttachments document.description

    descriptionDisplay = Discussion.sanitizeForDisplay.sanitizeHTML document.description

    createdAt = new Date()
    documentId = Discussion.documents.insert
      createdAt: createdAt
      updatedAt: createdAt
      lastActivity: createdAt
      author: user.getReference()
      title: document.title
      description: document.description
      descriptionDisplay: descriptionDisplay
      descriptionAttachments: ({_id} for _id in attachments)
      changes: [
        updatedAt: createdAt
        author: user.getReference()
        title: document.title
        description: document.description
      ]
      meetings: []

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
