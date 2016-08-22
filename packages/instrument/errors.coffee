{routeObject} = require './lib.coffee'

getStack = (error) ->
  if error
    StackTrace.fromError(error).then (stackframes) ->
      (stackframe.toString() for stackframe in stackframes)
  else
    Promise.resolve null

$(window).on 'error', (event) ->
  currentRoute = FlowRouter.current()
  if currentRoute
    route = routeObject currentRoute
  else
    route = null

  if navigator.languages
    languages = navigator.languages
  else if language = navigator.language or navigator.userLanguage
    languages = [language]
  else
    languages = []

  getStack(event.originalEvent.error).then (stack) ->
    Meteor.apply 'Activity.error', [
      message: event.originalEvent.message or ''
      filename: event.originalEvent.filename or ''
      lineNumber: parseInt(event.originalEvent.lineno) or null
      columnNumber: parseInt(event.originalEvent.colno) or null
      route: route
      stack: stack
      userAgent: navigator.userAgent or null
      languages: languages
      clientTime: new Date()
      windowWidth: window.innerWidth or null
      windowHeight: window.innerHeight or null
      screenWidth: screen.width or null
      screenHeight: screen.height or null
      devicePixelRatio: window.devicePixelRatio or null
      status: Meteor.status()
      protocol: Meteor.connection?._stream?.socket?.protocol or null
      settings: Meteor.settings
      release: Meteor.release
      version: __meteor_runtime_config__.VERSION
    ],
      noRetry: true
    ,
      (error, result) ->
        # We are ignoring errors.

  return
