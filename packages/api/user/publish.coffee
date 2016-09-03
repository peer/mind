new PublishEndpoint null, ->
  User.documents.find
    _id: @userId
  ,
    fields: User.EXTRA_PUBLISH_FIELDS()

new PublishEndpoint 'User.settings', ->
  User.documents.find
    _id: @userId
  ,
    fields:
      avatars: 1
      'services.facebook.id': 1
      'services.facebook.name': 1
      'services.facebook.link': 1
      'services.google.id': 1
      'services.google.name': 1
      'services.twitter.id': 1
      'services.twitter.screenName': 1
      researchData: 1

new PublishEndpoint 'User.profile', (userId) ->
  check userId, Match.DocumentId

  User.documents.find
    _id: userId
  ,
    fields: _.extend User.EXTRA_PUBLISH_FIELDS(),
      # Fields published by Meteor for logged-in users.
      username: 1,
      emails: 1
      # We use profile field differently than how Meteor is using it.
      profile: 1
