Accounts.onLogin (attempt) ->
  Activity.documents.insert
    timestamp: new Date()
    connection: attempt.connection.id
    user:
      _id: attempt.user._id
    type: 'login'
    level: Activity.LEVEL.ADMIN
    data:
      type: attempt.type
      clientAddress: attempt.connection.clientAddress
      userAgent: attempt.connection.httpHeaders['user-agent'] or null

Accounts.onLoginFailure (attempt) ->
  if attempt.user
    user =
      _id: attempt.user._id
  else
    user = null

  Activity.documents.insert
    timestamp: new Date()
    connection: attempt.connection.id
    user: user
    type: 'loginFailure'
    level: Activity.LEVEL.ADMIN
    data:
      type: attempt.type
      error: "#{attempt.error}"
      clientAddress: attempt.connection.clientAddress
      userAgent: attempt.connection.httpHeaders['user-agent'] or null

Accounts.onLogout (attempt) ->
  Activity.documents.insert
    timestamp: new Date()
    connection: attempt.connection.id
    user:
      _id: attempt.user._id
    type: 'logout'
    level: Activity.LEVEL.ADMIN
    data: null

MethodHooks.after 'changePassword', (options) ->
  if @userId
    user =
      _id: @userId
  else
    user = null

  if options.error
    Activity.documents.insert
      timestamp: new Date()
      connection: @connection.id
      user: user
      type: 'changePasswordFailure'
      level: Activity.LEVEL.ADMIN
      data:
        error: "#{options.error}"
        clientAddress: @connection.clientAddress
        userAgent: @connection.httpHeaders['user-agent'] or null
  else
    Activity.documents.insert
      timestamp: new Date()
      connection: @connection.id
      user: user
      type: 'changePassword'
      level: Activity.LEVEL.ADMIN
      data:
        clientAddress: @connection.clientAddress
        userAgent: @connection.httpHeaders['user-agent'] or null
