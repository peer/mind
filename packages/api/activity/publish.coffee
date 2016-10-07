new PublishEndpoint 'Activity.list', (personalized) ->
  check personalized, Boolean

  if Meteor.userId() and personalized
    query =
      level:
        $in: [Activity.LEVEL.USER, Activity.LEVEL.GENERAL]
      'forUsers._id': Meteor.userId()
  else
    query =
      level: Activity.LEVEL.GENERAL

  Activity.documents.find query,
    fields: Activity.PUBLISH_FIELDS()
