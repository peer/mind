class Comment.NewComponent extends UIComponent
  @register 'Comment.NewComponent'

  onCreated: ->
    super

    @canNew = new ComputedField =>
      !!Meteor.userId()

  currentDiscussionId: ->
    @ancestorComponent(Comment.ListComponent)?.currentDiscussionId()

  events: ->
    super.concat
      'submit .comment-new': @onSubmit

  onSubmit: (event) ->
    event.preventDefault()

    # TODO: We cannot use required for body input with trix.
    # TODO: Make a warning or something?
    return unless @hasBody()

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

  hasBody: ->
    # We require body to have at least some text content.
    $(@$('[name="body"]').val()).text()
