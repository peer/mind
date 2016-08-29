class Discussion.EditComponent extends Discussion.OneComponent
  @register 'Discussion.EditComponent'

  onCreated: ->
    super

    @autorun (computation) =>
      discussionId = @currentDiscussionId()
      @subscribe 'Discussion.forEdit', discussionId if discussionId

class Discussion.EditFormComponent extends UIComponent
  @register 'Discussion.EditFormComponent'

  onRendered: ->
    super

    Materialize.updateTextFields()

    Tracker.afterFlush =>
      # A bit of mangling to get cursor to focus at the end of the text.
      $title = @$('[name="title"]')
      title = $title.val()
      $title.focus().val('').val(title)

  onSubmit: (event) ->
    event.preventDefault()

    Meteor.call 'Discussion.update',
      _id: @data()._id
      title: @$('[name="title"]').val()
      description: @$('[name="description"]').val()
    ,
      (error, result) =>
        if error
          console.error "Update discussion error", error
          alert "Update discussion error: #{error.reason or error}"
          return

        # TODO: Should we check the result and if it is not expected show an error instead?

        for component in @childComponents 'EditorComponent'
          component.reset()

        # TODO: If we came here from closing discussion view, we should go back to that.
        FlowRouter.go 'Discussion.display',
          _id: @data()._id

FlowRouter.route '/discussion/edit/:_id',
  name: 'Discussion.edit'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Discussion.EditComponent'

    # We set PageTitle after we get discussion title.
