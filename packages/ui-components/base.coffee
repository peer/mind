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

class UIMixin extends UIComponent
  data: ->
    @mixinParent().data()

  callFirstWith: (args...) ->
    @mixinParent().callFirstWith args...

  autorun: (args...) ->
    @mixinParent().autorun args...
