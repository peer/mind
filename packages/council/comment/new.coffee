class Comment.NewComponent extends UIComponent
  @register 'Comment.NewComponent'

  currentDiscussionId: ->
    @ancestorComponent(Discussion.DisplayComponent)?.currentDiscussionId()

  events: ->
    super.concat
      'submit .comment-new': @onSubmit

  onSubmit: (event) ->
    event.preventDefault()

    Meteor.call 'Comment.new',
      body: @$('[name="body"]').val()
      discussion:
        _id: @currentDiscussionId()
    ,
      (error, documentId) =>
        if error
          console.error "Form error", error
          alert "Form error: #{error.reason or error}"
          return
