Meteor.methods
  'Discussion.new': (document) ->
    check document,
      title: Match.NonEmptyString
      description: Match.NonEmptyString

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    createdAt = new Date()
    Discussion.documents.insert
      createdAt: createdAt
      updatedAt: createdAt
      lastActivity: createdAt
      author: user.getReference()
      title: document.title
      titleChanges: [
        updatedAt: createdAt
        author: user.getReference()
        title: document.title
      ]
      description: document.description
      descriptionChanges: [
        updatedAt: createdAt
        author: user.getReference()
        description: document.description
      ]
      meetings: []
