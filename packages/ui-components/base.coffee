class UIComponent extends CommonComponent
  storageUrl: (filename, kwargs) ->
    Storage.url filename

  isSandstorm: ->
    !!__meteor_runtime_config__.SANDSTORM

class UIMixin extends CommonMixin
