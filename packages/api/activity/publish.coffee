new PublishEndpoint 'Activity.list', (personalized) ->
  check personalized, Boolean

  @enableScope()

  userId = Meteor.userId()
  if userId and personalized
    query =
      level:
        $in: [Activity.LEVEL.USER, Activity.LEVEL.GENERAL]
      'byUser._id':
        $ne: userId
      $or: [
        'forUsers._id': userId
      ,
        # A special case, we want all users to get notifications for new discussions and meetings.
        type:
          $in: ['discussionCreated', 'meetingCreated']
      ]
  else
    query =
      level: Activity.LEVEL.GENERAL

  @autorun (computation) =>
    @setData 'count', Activity.documents.find(query).count()

  @autorun (computation) =>
    limit = @data('limit') or 50
    check limit, Match.PositiveNumber

    Activity.documents.find query,
      fields: Activity.PUBLISH_FIELDS()
      limit: limit
      sort:
        # The newest first.
        timestamp: -1
