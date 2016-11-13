new PublishEndpoint 'Activity.list', (personalized, initialLimit) ->
  check personalized, Boolean
  check initialLimit, Match.PositiveNumber

  @enableScope()

  userId = Meteor.userId()
  if personalized
    if userId
      query = Activity.personalizedActivityQuery userId
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
    query = Activity.personalizedActivityQuery userId
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
