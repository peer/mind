new PublishEndpoint 'Activity.list', (personalized) ->
  check personalized, Boolean

  @enableScope()

  userId = Meteor.userId()
  if userId and personalized
    query =
      level:
        $in: [Activity.LEVEL.USER, Activity.LEVEL.GENERAL]
      'forUsers._id': userId
      'byUser._id':
        $ne: userId
  else
    query =
      level: Activity.LEVEL.GENERAL

  Activity.documents.find query,
    fields: Activity.PUBLISH_FIELDS()
