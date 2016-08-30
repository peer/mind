class MetadataComponent extends UIComponent
  @register 'MetadataComponent'

  constructor: (kwargs) ->
    super

    _.extend @, _.pick (kwargs?.hash or {}), 'noAvatar', 'editButton'

  canEdit: ->
    @callAncestorWith 'canEdit'

  renderEditButton: (parentComponent) ->
    parentComponent ?= @currentComponent()

    if _.isString @editButton
      component = @constructor.getComponent @editButton
    else if @editButton
      component = @editButton
    else
      component = @constructor.getComponent 'EditButton'

    component.renderComponent parentComponent

  renderExtraMetadataButtons: (parentComponent) ->
    parentComponent ?= @currentComponent()

    @callAncestorWith('renderExtraMetadataButtons', parentComponent, @component()) or null

  renderMetadataTimestamp: (parentComponent) ->
    parentComponent ?= @currentComponent()

    @callAncestorWith('renderMetadataTimestamp', parentComponent, @component()) or MetadataDefaultTimestampComponent.renderComponent parentComponent

class MetadataDefaultTimestampComponent extends UIComponent
  @register 'MetadataDefaultTimestampComponent'