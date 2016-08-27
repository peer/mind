class Comment.NewComponent extends UIComponent
  @register 'Comment.NewComponent'

  onCreated: ->
    super

    @canNew = new ComputedField =>
      User.hasPermission User.PERMISSIONS.COMMENT_NEW

  currentDiscussionId: ->
    @ancestorComponent(Comment.ListComponent)?.currentDiscussionId()

  events: ->
    super.concat
      'submit .comment-new': @onSubmit

  onSubmit: (event) ->
    event.preventDefault()

    # TODO: We cannot use required for body input with trix.
    unless @hasBody()
      # TODO: Use flash messages.
      alert "Comment is required."
      return

    Meteor.call 'Comment.new',
      body: @$('[name="body"]').val()
      discussion:
        _id: @currentDiscussionId()
    ,
      (error, documentId) =>
        if error
          console.error "New comment error", error
          alert "New comment error: #{error.reason or error}"
          return

        event.target.reset()

        for component in @childComponents 'EditorComponent'
          component.clearStoredState()

  hasBody: ->
    # We require body to have at least some text content or a figure.
    $body = $($.parseHTML(@$('[name="body"]').val()))
    $body.text() or $body.has('figure').length
