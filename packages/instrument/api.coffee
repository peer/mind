{routeObjectMatch, escapeKeys} = require './lib.coffee'

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
      data: escapeKeys routeObject

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
      data: escapeKeys error

  'Activity.ui': (type, documentType, document) ->
    check type, Match.NonEmptyString
    check documentType, Match.NonEmptyString
    check documentType, Match.Where (x) ->
      x in [Comment.Meta._name, Discussion.Meta._name, Meeting.Meta._name, Motion.Meta._name, Point.Meta._name]
    check document,
      _id: Match.DocumentId

    if @userId
      user =
        _id: @userId
    else
      user = null

    data =
      type: type
    data[documentType.toLowerCase()] = document

    Activity.documents.insert
      timestamp: new Date()
      connection: @connection.id
      user: user
      type: 'ui'
      level: Activity.LEVEL.DEBUG
      data: data

  'Activity.visibility': (visible) ->
    check visible, Boolean

    if @userId
      user =
        _id: @userId
    else
      user = null

    Activity.documents.insert
      timestamp: new Date()
      connection: @connection.id
      user: user
      type: 'visibility'
      level: Activity.LEVEL.DEBUG
      data:
        visible: visible

  'Activity.focus': (focused) ->
    check focused, Boolean

    if @userId
      user =
        _id: @userId
    else
      user = null

    Activity.documents.insert
      timestamp: new Date()
      connection: @connection.id
      user: user
      type: 'focus'
      level: Activity.LEVEL.DEBUG
      data:
        focused: focused
