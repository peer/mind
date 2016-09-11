class FooterComponent extends UIComponent
  @register 'FooterComponent'

  @fixedButtonComponent = new ReactiveField null, (a, b) -> a is b
  @fixedButtonDataContext = new ReactiveField null

  version: ->
    "Version: #{__meteor_runtime_config__.VERSION or "unknown"}"

  renderFixedButton: (parentComponent) ->
    parentComponent ?= @currentComponent()

    component = @constructor.fixedButtonComponent()

    component = @constructor.getComponent component if _.isString component

    component?.renderComponent(parentComponent) or null

  fixedButtonDataContext: ->
    # We cannot access constructor from the template. And we always want to return a data context
    # because we want to render the fixed button also for no data context (and #with works like #if
    # and does not render its content if the argument is false).
    @constructor.fixedButtonDataContext() or {}
