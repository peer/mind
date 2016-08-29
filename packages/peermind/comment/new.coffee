class Comment.NewComponent extends UIComponent
  @register 'Comment.NewComponent'

  onCreated: ->
    super

    @canNew = new ComputedField =>
      # In contrast with points and motions, we allow comments to be made for closed
      # discussions, but we display a message warning an user that they should consider
      # opening a new discussion instead.
      User.hasPermission(User.PERMISSIONS.COMMENT_NEW) and (@discussionIsOpen() or @discussionIsClosed())

  currentDiscussionId: ->
    @ancestorComponent(Comment.ListComponent)?.currentDiscussionId()

  discussionIsOpen: ->
    @ancestorComponent(Comment.ListComponent)?.discussionIsOpen()

  discussionIsClosed: ->
    @ancestorComponent(Comment.ListComponent)?.discussionIsClosed()

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
          component.reset()

  hasBody: ->
    # TODO: Search all descendant components, not just children.
    _.every(component.hasContent() for component in @childComponents 'EditorComponent')
