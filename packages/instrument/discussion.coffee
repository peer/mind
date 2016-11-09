MethodHooks.after 'Discussion.follow', (options) ->
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
      type: 'discussionFollow'
      level: Activity.LEVEL.DEBUG
      data:
        discussion:
          _id: options.arguments[0]
        type: options.arguments[1]

  options.result

MethodHooks.after 'Discussion.seen', (options) ->
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
      type: 'discussionSeen'
      level: Activity.LEVEL.DEBUG
      data:
        activity:
          _id: options.arguments[0]

  options.result
