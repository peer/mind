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
