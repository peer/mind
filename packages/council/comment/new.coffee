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
