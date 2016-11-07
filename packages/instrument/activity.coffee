MethodHooks.after 'Activity.seenPersonalized', (options) ->
  if @userId
    user =
      _id: @userId
  else
    user = null

  unless options.error
    Activity.documents.insert
      timestamp: new Date()
      connection: @connection.id
      byUser: user
      type: 'activitySeenPersonalized'
      level: Activity.LEVEL.DEBUG
      data:
        activity:
          _id: options.arguments[0]

  options.result
