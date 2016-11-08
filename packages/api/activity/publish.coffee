personalizedActivityQuery = (userId) ->
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

new PublishEndpoint 'Activity.list', (personalized, initialLimit) ->
  check personalized, Boolean
  check initialLimit, Match.PositiveNumber

  @enableScope()

  userId = Meteor.userId()
  if personalized
    if userId
      query = personalizedActivityQuery userId
    else
      return []
  else
    query =
      level: Activity.LEVEL.GENERAL

  @autorun (computation) =>
    @setData 'count', Activity.documents.find(query).count()

  @autorun (computation) =>
    limit = @data('limit') or initialLimit
    check limit, Match.PositiveNumber

    Activity.documents.find query,
      fields: Activity.PUBLISH_FIELDS()
      limit: limit
      sort:
        # The newest first.
        timestamp: -1

new PublishEndpoint 'Activity.unseenPersonalizedCount', ->
  @enableScope()

  userId = Meteor.userId()

  return [] unless userId

  lastSeenPersonalizedActivity = new ComputedField =>
    User.documents.findOne(userId,
      fields:
        lastSeenPersonalizedActivity: 1
    )?.lastSeenPersonalizedActivity or null
  ,
    true

  @onStop =>
    lastSeenPersonalizedActivity.stop()

  @autorun (computation) =>
    query = personalizedActivityQuery userId
    if lastSeenPersonalizedActivity()
      _.extend query,
        timestamp:
          $gt: lastSeenPersonalizedActivity()

    activities = Activity.combineActivities Activity.documents.find(query,
      fields: Activity.PUBLISH_FIELDS()
      sort:
        # The newest first.
        timestamp: -1
    ).fetch()

    @setData 'count', Math.min activities.length, 999

  @ready()

new PublishEndpoint 'Activity.discussion', (discussionId) ->
  check discussionId, Match.DocumentId

  Activity.documents.find
    'data.discussion._id': discussionId
    type:
      $in: [
        'discussionCreated'
        'discussionClosed'
        'motionCreated'
        'motionOpened'
        'motionClosed'
        'motionWithdrawn'
      ]
  ,
    fields: Activity.PUBLISH_FIELDS()
