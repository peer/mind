for type in ['Comment', 'Motion', 'Point']
  do (type) ->
    MethodHooks.after "#{type}.upvote", (options) ->
      if @userId
        user =
          _id: @userId
      else
        user = null

      unless options.error and options.result
        data = {}
        data[type.toLowerCase()] =
          _id: options.arguments[0]

        Activity.documents.insert
          timestamp: new Date()
          connection: @connection.id
          byUser: user
          type: 'upvote'
          level: Activity.LEVEL.DEBUG
          data: data

      options.result

    MethodHooks.after "#{type}.removeUpvote", (options) ->
      if @userId
        user =
          _id: @userId
      else
        user = null

      unless options.error and options.result
        data = {}
        data[type.toLowerCase()] =
          _id: options.arguments[0]

        Activity.documents.insert
          timestamp: new Date()
          connection: @connection.id
          byUser: user
          type: 'removeUpvote'
          level: Activity.LEVEL.DEBUG
          data: data

      options.result
