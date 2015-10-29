class MetadataComponent extends UIComponent
  @register 'MetadataComponent'

  constructor: (kwargs) ->
    super

    _.extend @, _.pick (kwargs?.hash or {}), 'noAvatar'

  canEdit: ->
    @callAncestorWith 'canEdit'
