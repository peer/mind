expirationMsFromDuration = (duration) ->
  # Default values from  moment/src/lib/duration/humanize.js.
  thresholds =
    s: 45 # seconds to minute
    m: 45 # minutes to hour
    h: 22 # hours to day

  seconds = Math.round(duration.as 's')
  minutes = Math.round(duration.as 'm')
  hours = Math.round(duration.as 'h')

  if seconds < thresholds.s
    (thresholds.s - seconds) * 1000 + 500
  else if minutes < thresholds.m
    (60 - seconds % 60) * 1000 + 500
  else if hours < thresholds.h
    ((60 * 60) - seconds % (60 * 60)) * 1000 + 500
  else
    ((24 * 60 * 60) - seconds % (24 * 60 * 60)) * 1000 + 500

invalidateAfter = (expirationMs) ->
  computation = Tracker.currentComputation
  handle = Meteor.setTimeout =>
    computation.invalidate()
  ,
    expirationMs
  computation.onInvalidate =>
    Meteor.clearTimeout handle if handle
    handle = null

class UIComponent extends BlazeComponent
  # A version of BlazeComponent.subscribe which logs errors to the console if no error callback is specified.
  subscribe: (args...) ->
    lastArgument = args[args.length - 1]

    callbacks = {}
    if _.isFunction lastArgument
      callbacks.onReady = args.pop()
    else if _.any [lastArgument?.onReady, lastArgument?.onError, lastArgument?.onStop], _.isFunction
      callbacks = args.pop()

    unless callbacks.onError or callbacks.onStop
      callbacks.onStop = (error) =>
        console.error "Subscription '#{args[0]}' error", error if error

    args.push callbacks

    super args...

  pathFor: (pathName, kwargs) ->
    params = kwargs?.hash?.params or {}
    queryParams = kwargs?.hash?.query or {}

    FlowRouter.path pathName, params, queryParams

  ancestorComponent: (componentClass) ->
    component = @parentComponent()
    while component and component not instanceof componentClass
      component = component.parentComponent()
    component

  callAncestorWith: (propertyName, args...) ->
    component = @parentComponent()
    while component and not component.getFirstWith null, propertyName
      component = component.parentComponent()
    component?.callFirstWith null, propertyName, args...

  $or: (args...) ->
    # Removing kwargs.
    assert args[args.length - 1] instanceof Spacebars.kw
    args.pop()

    _.some args

  $and: (args...) ->
    # Removing kwargs.
    assert args[args.length - 1] instanceof Spacebars.kw
    args.pop()

    _.every args

  $not: (args...) ->
    # Removing kwargs.
    assert args[args.length - 1] instanceof Spacebars.kw
    args.pop()

    not args[0]

  insertDOMElement: (parent, node, before, next) ->
    next ?= =>
      super parent, node, before
      true

    return next() unless @callFirstWith @, 'insertDOMElement', parent, node, before, next

    # It has been handled.
    true

  moveDOMElement: (parent, node, before, next) ->
    next ?= =>
      super parent, node, before
      true

    return next() unless @callFirstWith @, 'moveDOMElement', parent, node, before, next

    # It has been handled.
    true

  removeDOMElement: (parent, node, next) ->
    next ?= =>
      super parent, node
      true

    return next() unless @callFirstWith @, 'removeDOMElement', parent, node, next

    # It has been handled.
    true

  fromNow: (date, withoutSuffix, options) ->
    if withoutSuffix instanceof Spacebars.kw
      options = withoutSuffix
      withoutSuffix = false

    momentDate = moment(date)

    if Tracker.active
      absoluteDuration = moment.duration(to: momentDate, from: moment()).abs()
      expirationMs = expirationMsFromDuration absoluteDuration
      invalidateAfter expirationMs

    momentDate.fromNow withoutSuffix

  DEFAULT_DATETIME_FORMAT:
    'llll'

  DEFAULT_DATE_FORMAT:
    'll'

  DEFAULT_TIME_FORMAT:
    'LT'

  formatDate: (date, format) ->
    format = null if format instanceof Spacebars.kw

    moment(date).format format

  # TODO: Support internationalization.
  formatDuration: (from, to, size) ->
    size = null if size instanceof Spacebars.kw

    reactive = not (from and to)

    from ?= new Date()
    to ?= new Date()

    duration = moment.duration({from, to}).abs()

    minutes = Math.round(duration.as 'm') % 60
    hours = Math.round(duration.as 'h') % 24
    days = Math.round(duration.as 'd') % 7
    weeks = Math.floor(Math.round(duration.as 'd') / 7)

    partials = [
      key: 'week'
      value: weeks
    ,
      key: 'day'
      value: days
    ,
      key: 'hour'
      value: hours
    ,
      key: 'minute'
      value: minutes
    ]

    # Trim zero values from the left.
    while partials.length and partials[0].value is 0
      partials.shift()

    # Cut the length to provided size.
    partials = partials[0...size] if size

    if reactive and Tracker.active and partials.length
      seconds = Math.round(duration.as 's')
      lastPartial = partials[partials.length - 1].key
      if lastPartial is 'minute'
        expirationMs = (60 - seconds % 60) * 1000 + 500
      else if lastPartial is 'hour'
        expirationMs = ((60 * 60) - seconds % (60 * 60)) * 1000 + 500
      else
        expirationMs = ((24 * 60 * 60) - seconds % (24 * 60 * 60)) * 1000 + 500

      invalidateAfter expirationMs

    partials = for {key, value} in partials
      # Maybe there are some zero values in-between, skip them.
      continue if value is 0

      key = "#{key}s" if value isnt 1

      "#{value} #{key}"

    partials.join ' '

class UIMixin extends UIComponent
  data: ->
    @mixinParent().data()

  callFirstWith: (args...) ->
    @mixinParent().callFirstWith args...

  autorun: (args...) ->
    @mixinParent().autorun args...
