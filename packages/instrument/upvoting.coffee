for type in ['Comment', 'Motion', 'Point']
  MethodHooks.after "#{type}.upvote", (options) ->
    if @userId
      user =
        _id: @userId
    else
      user = null

    unless options.error and options.result
      Activity.documents.insert
        timestamp: new Date()
        connection: @connection.id
        user: user
        type: 'upvote'
        level: Activity.LEVEL.DEBUG
        data:
          document:
            _id: options.arguments[0]
            _type: type

    options.result

  MethodHooks.after "#{type}.removeUpvote", (options) ->
    if @userId
      user =
        _id: @userId
    else
      user = null

    unless options.error and options.result
      Activity.documents.insert
        timestamp: new Date()
        connection: @connection.id
        user: user
        type: 'removeUpvote'
        level: Activity.LEVEL.DEBUG
        data:
          document:
            _id: options.arguments[0]
            _type: type

    options.result
