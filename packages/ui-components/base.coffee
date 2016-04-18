class UIComponent extends CommonComponent
  storageUrl: (filename, kwargs) ->
    Storage.url filename

  isSandstorm: ->
    !!Meteor.settings?.public?.sandstorm

class UIMixin extends CommonMixin
