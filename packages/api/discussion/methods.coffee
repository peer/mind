Meteor.methods
  'Discussion.new': (document) ->
    check document,
      title: Match.NonEmptyString
      description: Match.NonEmptyString

    attachments = []

    document.description = share.sanitize.sanitizeHTML document.description

    if Meteor.isServer
      descriptionText = cheerio.load(document.description).root().text()
    else
      descriptionText = $('<div/>').append($.parseHTML(document.description)).text()

    check descriptionText, Match.NonEmptyString

    attachments = share.extractAttachments document.description

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
      changes: [
        updatedAt: createdAt
        author: user.getReference()
        title: document.title
        description: document.description
      ]
      meetings: []
      attachments: ({_id} for _id in attachments)

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
