Meteor.methods
  'Discussion.new': (document) ->
    check document,
      title: Match.NonEmptyString
      description: Match.NonEmptyString

    attachments = []

    document.description = Discussion.sanitize.sanitizeHTML document.description

    if Meteor.isServer
      descriptionText = cheerio.load(document.description).root().text()
    else
      descriptionText = $('<div/>').append($.parseHTML(document.description)).text()

    check descriptionText, Match.NonEmptyString

    attachments = Discussion.extractAttachments document.description

    descriptionDisplay = Discussion.sanitizeForDisplay.sanitizeHTML document.description

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

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
