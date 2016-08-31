class Discussion.EditComponent extends Discussion.OneComponent
  @register 'Discussion.EditComponent'

  onCreated: ->
    super

    @autorun (computation) =>
      discussionId = @currentDiscussionId()
      @subscribe 'Discussion.forEdit', discussionId if discussionId

class Discussion.EditFormComponent extends UIComponent
  @register 'Discussion.EditFormComponent'

  onCreated: ->
    super

    @canEditClose = new ComputedField =>
      User.hasPermission(User.PERMISSIONS.DISCUSSION_CLOSE)

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

    discussionId = @data()._id

    passingMotions = @$('[name="passingMotions"]:checked').map((i, el) =>
      $(el).val()
    ).get()

    closingNote = @$('[name="closingNote"]').val() or ''

    Meteor.call 'Discussion.update',
      _id: discussionId
      title: @$('[name="title"]').val()
      description: @$('[name="description"]').val()
    ,
      passingMotions
    ,
      closingNote
    ,
      (error, result) =>
        if error
          console.error "Update discussion error", error
          alert "Update discussion error: #{error.reason or error}"
          return

        # TODO: Should we check the result and if it is not expected show an error instead?
        #       For this method, the result is an array [changedUpdate, changedClosing].

        for component in @childComponents 'EditorComponent'
          component.reset()

        # TODO: If we came here from closing discussion view, we should go back to that.
        FlowRouter.go 'Discussion.display',
          _id: discussionId

FlowRouter.route '/discussion/edit/:_id',
  name: 'Discussion.edit'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Discussion.EditComponent'

    # We set PageTitle after we get discussion title.
