MethodHooks.after 'Meeting.seen', (options) ->
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
      type: 'meetingSeen'
      level: Activity.LEVEL.DEBUG
      data:
        meeting:
          _id: options.arguments[0]

  options.result
