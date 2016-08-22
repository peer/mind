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
