Meteor.methods
  'Discussion.new': (document) ->
    check document,
      title: Match.NonEmptyString
      description: Match.NonEmptyString

    attachments = []

    if Meteor.isServer
      document.description = share.sanitize.sanitizeHTML document.description

      check cheerio.load(document.description).root().text(), Match.NonEmptyString

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

    if Meteor.isServer
      StorageFile.documents.update
        _id:
          $in: attachments
      ,
        $set:
          active: true
      ,
        multi: true

    documentId
