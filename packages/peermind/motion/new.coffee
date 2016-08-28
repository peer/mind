class Motion.NewComponent extends UIComponent
  @register 'Motion.NewComponent'

  onCreated: ->
    super

    @canNew = new ComputedField =>
      User.hasPermission User.PERMISSIONS.MOTION_NEW

  currentDiscussionId: ->
    @ancestorComponent(Motion.ListComponent)?.currentDiscussionId()

  onSubmit: (event) ->
    event.preventDefault()

    # TODO: We cannot use required for body input with trix.
    unless @hasBody()
      # TODO: Use flash messages.
      alert "Motion is required."
      return

    Meteor.call 'Motion.new',
      body: @$('[name="body"]').val()
      discussion:
        _id: @currentDiscussionId()
    ,
      (error, documentId) =>
        if error
          console.error "New motion error", error
          alert "New motion error: #{error.reason or error}"
          return

        event.target.reset()

        for component in @childComponents 'EditorComponent'
          component.clearStoredState()

  hasBody: ->
    # We require body to have at least some text content or a figure.
    $body = $($.parseHTML(@$('[name="body"]').val()))
    $body.text() or $body.has('figure').length
