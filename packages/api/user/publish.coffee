new PublishEndpoint null, ->
  User.documents.find
    _id: @userId
  ,
    fields: User.EXTRA_PUBLISH_FIELDS()
