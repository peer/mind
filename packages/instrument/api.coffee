{routeObjectMatch} = require './lib.coffee'

Meteor.methods
  'Activity.route': (routeObject) ->
    check routeObject, routeObjectMatch

    if @userId
      user =
        _id: @userId
    else
      user = null

    Activity.documents.insert
      timestamp: new Date()
      connection: @connection.id
      user: user
      type: 'route'
      level: Activity.LEVEL.DEBUG
      data: routeObject

  'Activity.error': (error) ->
    check error,
      message: String
      filename: String
      lineNumber: Match.OneOf Match.Integer, null
      columnNumber: Match.OneOf Match.Integer, null
      route: routeObjectMatch
      stack: [Match.NonEmptyString]
      userAgent: Match.OneOf Match.NonEmptyString, null
      languages: [Match.NonEmptyString]
      doNotTrack: Boolean
      clientTime: Date
      windowWidth: Match.OneOf Match.Integer, null
      windowHeight: Match.OneOf Match.Integer, null
      screenWidth: Match.OneOf Match.Integer, null
      screenHeight: Match.OneOf Match.Integer, null
      devicePixelRatio: Match.OneOf Number, null
      status: Object
      protocol: Match.OneOf Match.NonEmptyString, null
      settings: Object
      release: Match.NonEmptyString
      version: Match.OneOf Match.NonEmptyString, null

    if @userId
      user =
        _id: @userId
    else
      user = null

    Activity.documents.insert
      timestamp: new Date()
      connection: @connection.id
      user: user
      type: 'error'
      level: Activity.LEVEL.ERROR
      data: error
