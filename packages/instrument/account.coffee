Accounts.onLogin (attempt) ->
  Activity.documents.insert
    timestamp: new Date()
    connection: attempt.connection.id
    byUser:
      _id: attempt.user._id
    type: 'login'
    level: Activity.LEVEL.ADMIN
    data:
      type: attempt.type
      methodName: attempt.methodName
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
    byUser: user
    type: 'loginFailure'
    level: Activity.LEVEL.ADMIN
    data:
      type: attempt.type
      methodName: attempt.methodName
      error: "#{attempt.error}"
      clientAddress: attempt.connection.clientAddress
      userAgent: attempt.connection.httpHeaders['user-agent'] or null

Accounts.onLogout (attempt) ->
  if attempt.user
    user =
      _id: attempt.user._id
  else
    user = null

  Activity.documents.insert
    timestamp: new Date()
    connection: attempt.connection.id
    byUser: user
    type: 'logout'
    level: Activity.LEVEL.ADMIN
    data: null

MethodHooks.after 'Account.unlinkAccount', (options) ->
  if @userId
    user =
      _id: @userId
  else
    user = null

  if options.error
    Activity.documents.insert
      timestamp: new Date()
      connection: @connection.id
      byUser: user
      type: 'accountUnlinkFailure'
      level: Activity.LEVEL.ERROR
      data:
        error: "#{options.error}"
        clientAddress: @connection.clientAddress
        userAgent: @connection.httpHeaders['user-agent'] or null
  else
    Activity.documents.insert
      timestamp: new Date()
      connection: @connection.id
      byUser: user
      type: 'accountUnlink'
      level: Activity.LEVEL.ADMIN
      data:
        serviceName: options.arguments[0]
        clientAddress: @connection.clientAddress
        userAgent: @connection.httpHeaders['user-agent'] or null

  options.result

MethodHooks.after 'Account.researchData', (options) ->
  if @userId
    user =
      _id: @userId
  else
    user = null

  if options.error
    Activity.documents.insert
      timestamp: new Date()
      connection: @connection.id
      byUser: user
      type: 'researchDataFailure'
      level: Activity.LEVEL.ERROR
      data:
        error: "#{options.error}"
  else
    Activity.documents.insert
      timestamp: new Date()
      connection: @connection.id
      byUser: user
      type: 'researchData'
      level: Activity.LEVEL.DEBUG
      data:
        consent: options.arguments[0]

  options.result

MethodHooks.before 'Account.changeName', (options) ->
  if @userId
    # We store current name away so that we can log it.
    @_oldName = User.documents.findOne(@userId, fields: name: 1)?.name or null

MethodHooks.after 'Account.changeName', (options) ->
  if @userId
    user =
      _id: @userId
  else
    user = null

  if options.error
    Activity.documents.insert
      timestamp: new Date()
      connection: @connection.id
      byUser: user
      type: 'nameChangeFailure'
      level: Activity.LEVEL.ERROR
      data:
        error: "#{options.error}"
        clientAddress: @connection.clientAddress
        userAgent: @connection.httpHeaders['user-agent'] or null
  else
    Activity.documents.insert
      timestamp: new Date()
      connection: @connection.id
      byUser: user
      type: 'nameChange'
      level: Activity.LEVEL.ADMIN
      data:
        oldName: @_oldName
        newName: options.arguments[0]
        clientAddress: @connection.clientAddress
        userAgent: @connection.httpHeaders['user-agent'] or null

  options.result

unless __meteor_runtime_config__.SANDSTORM
  MethodHooks.before 'Account.changeUsername', (options) ->
    if @userId
      # We store current username away so that we can log it.
      @_oldUsername = User.documents.findOne(@userId, fields: username: 1)?.username or null

  MethodHooks.after 'Account.changeUsername', (options) ->
    if @userId
      user =
        _id: @userId
    else
      user = null

    if options.error
      Activity.documents.insert
        timestamp: new Date()
        connection: @connection.id
        byUser: user
        type: 'usernameChangeFailure'
        level: Activity.LEVEL.ERROR
        data:
          error: "#{options.error}"
          clientAddress: @connection.clientAddress
          userAgent: @connection.httpHeaders['user-agent'] or null
    else
      Activity.documents.insert
        timestamp: new Date()
        connection: @connection.id
        byUser: user
        type: 'usernameChange'
        level: Activity.LEVEL.ADMIN
        data:
          oldUsername: @_oldUsername
          newUsername: options.arguments[0]
          clientAddress: @connection.clientAddress
          userAgent: @connection.httpHeaders['user-agent'] or null

    options.result

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
        byUser: user
        type: 'passwordChangeFailure'
        level: Activity.LEVEL.ERROR
        data:
          error: "#{options.error}"
          clientAddress: @connection.clientAddress
          userAgent: @connection.httpHeaders['user-agent'] or null
    else
      Activity.documents.insert
        timestamp: new Date()
        connection: @connection.id
        byUser: user
        type: 'passwordChange'
        level: Activity.LEVEL.ADMIN
        data:
          clientAddress: @connection.clientAddress
          userAgent: @connection.httpHeaders['user-agent'] or null

    options.result

  MethodHooks.after 'Account.selectAvatar', (options) ->
    if @userId
      user =
        _id: @userId
    else
      user = null

    if options.error
      Activity.documents.insert
        timestamp: new Date()
        connection: @connection.id
        byUser: user
        type: 'avatarSelectionFailure'
        level: Activity.LEVEL.ERROR
        data:
          error: "#{options.error}"
          clientAddress: @connection.clientAddress
          userAgent: @connection.httpHeaders['user-agent'] or null
    else
      Activity.documents.insert
        timestamp: new Date()
        connection: @connection.id
        byUser: user
        type: 'avatarSelection'
        level: Activity.LEVEL.ADMIN
        data:
          name: options.arguments[0]
          argument: options.arguments[1] or null
          clientAddress: @connection.clientAddress
          userAgent: @connection.httpHeaders['user-agent'] or null

    options.result
