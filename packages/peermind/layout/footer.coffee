class FooterComponent extends UIComponent
  @register 'FooterComponent'

  @_fixedButtonComponent = new ReactiveField null, (a, b) -> a is b
  @_fixedButtonStack = 0

  @fixedButtonDataContext = new ReactiveField null

  @setFixedButton: (component) ->
    fixedButtonComponent = Tracker.nonreactive =>
      @_fixedButtonComponent()

    if fixedButtonComponent and component and fixedButtonComponent is component
      @_fixedButtonStack++
    else
      if fixedButtonComponent and component and @_fixedButtonStack > 0
        console.warn "Overriding the fixed button '#{fixedButtonComponent.componentName?() or fixedButtonComponent}' with '#{component.componentName?() or component}'."

      @_fixedButtonComponent component
      @_fixedButtonStack = 1

  @removeFixedButton: ->
    @_fixedButtonStack--

    if @_fixedButtonStack <= 0
      @_fixedButtonComponent null
      @_fixedButtonStack = 0

  version: ->
    "Version: #{__meteor_runtime_config__.VERSION or "unknown"}"

  renderFixedButton: (parentComponent) ->
    parentComponent ?= @currentComponent()

    component = @constructor._fixedButtonComponent()

    component = @constructor.getComponent component if _.isString component

    component?.renderComponent(parentComponent) or null

  fixedButtonDataContext: ->
    # We cannot access constructor from the template. And we always want to return a data context
    # because we want to render the fixed button also for no data context (and #with works like #if
    # and does not render its content if the argument is false).
    @constructor.fixedButtonDataContext() or {}
