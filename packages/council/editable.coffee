# TODO: Make a component once the animations hook bug is fixed.
#class EditButton extends UIComponent
#  @register 'EditButton'

class share.EditableMixin extends UIMixin
  onCreated: ->
    super

    @_isBeingEdited = new ReactiveField false

    @_editingSubscriptions = new ReactiveField []

    @editingSubscriptionsReady = new ComputedField =>
      _.all @_editingSubscriptions(), (handle) =>
        handle.ready()

    # This has to be before the isBeingEdited computed field so that _editingSubscriptions
    # is changed on _isBeingEdited's change before computed field is reevaluated.
    @autorun (computation) =>
      return unless @_isBeingEdited()

      subscriptions = @callFirstWith null, 'editingSubscriptions'

      subscriptions ?= []
      subscriptions = [subscriptions] unless _.isArray subscriptions

      @_editingSubscriptions subscriptions

    @isBeingEdited = new ComputedField =>
      @_isBeingEdited() and @editingSubscriptionsReady()

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

    @_isBeingEdited true

  onSaveEditButton: (event) ->
    event.preventDefault()

    @callFirstWith null, 'onSaveEdit', event, =>
      @_isBeingEdited false

  onCancelEditButton: (event) ->
    event.preventDefault()

    @_isBeingEdited false
