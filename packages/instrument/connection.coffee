Meteor.onConnection (connection) ->
  connection.onClose ->
    Activity.documents.insert
      timestamp: new Date()
      connection: connection.id
      byUser: null
      type: 'connectionEnd'
      level: Activity.LEVEL.DEBUG
      data: null

  Activity.documents.insert
    timestamp: new Date()
    connection: connection.id
    byUser: null
    type: 'connectionStart'
    level: Activity.LEVEL.DEBUG
    data:
      clientAddress: connection.clientAddress
      userAgent: connection.httpHeaders['user-agent'] or null
      acceptLanguage: connection.httpHeaders['accept-language'] or null
      release: Meteor.release
      version: __meteor_runtime_config__.VERSION
