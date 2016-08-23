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

  events: ->
    super.concat
      'submit .discussion-edit': @onSubmit

  onSubmit: (event) ->
    event.preventDefault()

    # TODO: We cannot use required for description input with trix.
    unless @hasDescription()
      # TODO: Use flash messages.
      alert "Description is required."
      return

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

        FlowRouter.go 'Discussion.display',
          _id: @data()._id

  hasDescription: ->
    # We require description to have at least some text content or a figure.
    $description = $($.parseHTML(@$('[name="description"]').val()))
    $description.text() or $description.has('figure').length

FlowRouter.route '/discussion/edit/:_id',
  name: 'Discussion.edit'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Discussion.EditComponent'

    # We set PageTitle after we get discussion title.
