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

Accounts.onLogout (attempt) ->
  Activity.documents.insert
    timestamp: new Date()
    connection: attempt.connection.id
    user:
      _id: attempt.user._id
    type: 'logout'
    level: Activity.LEVEL.ADMIN
    data: null
