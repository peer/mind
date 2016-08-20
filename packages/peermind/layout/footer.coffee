class FooterComponent extends UIComponent
  @register 'FooterComponent'

  version: ->
    "Version: #{__meteor_runtime_config__.VERSION or "unknown"}"
