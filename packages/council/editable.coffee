# TODO: Make a component once the animations hook bug is fixed.
#class EditButton extends UIComponent
#  @register 'EditButton'

class share.EditableMixin extends UIMixin
  onCreated: ->
    super

    @isBeingEdited = new ReactiveField false

    @autorun (computation) =>
      return unless @isBeingEdited()

      @callFirstWith null, 'onBeingEdited'

  events: ->
    super.concat
      'click .edit-button': @onEditButton
      'submit .editable-form': @onSaveEditButton
      'click .cancel-edit-button': @onCancelEditButton

  onEditButton: (event) ->
    event.preventDefault()

    @isBeingEdited true

  onSaveEditButton: (event) ->
    event.preventDefault()

    @callFirstWith null, 'onSaveEdit', event, =>
      @isBeingEdited false

  onCancelEditButton: (event) ->
    event.preventDefault()

    @isBeingEdited false
