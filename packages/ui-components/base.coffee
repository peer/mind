class UIComponent extends BlazeComponent
  # A version of BlazeComponent.subscribe which logs errors to the console if no error callback is specified.
  subscribe: (args...) ->
    lastArgument = args[args.length - 1]

    callbacks = {}
    if _.isFunction lastArgument
      callbacks.onReady = params.pop()
    else if _.any [lastArgument?.onReady, lastArgument?.onError, lastArgument?.onStop], _.isFunction
      callbacks = params.pop()

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
    component = @
    while component and component not instanceof componentClass
      component = component.parentComponent()
    component

  $or: (args...) ->
    # Removing kwargs.
    args.pop()
    _.some args

  $and: (args...) ->
    # Removing kwargs.
    args.pop()
    _.every args
