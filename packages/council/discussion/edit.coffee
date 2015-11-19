class Discussion.EditComponent extends Discussion.DisplayComponent
  @register 'Discussion.EditComponent'

  onCreated: ->
    super

    @autorun (computation) =>
      discussionId = @currentDiscussionId()
      @subscribe 'Discussion.forEdit', discussionId if discussionId

  events: ->
    super.concat
      'submit .discussion-edit': @onSubmit

  onSubmit: (event) ->
    event.preventDefault()

    # TODO: We cannot use required for description input with trix.
    # TODO: Make a warning or something?
    return unless @hasDescription()

    Meteor.call 'Discussion.update',
      _id: @currentDiscussionId()
      title: @$('[name="title"]').val()
      description: @$('[name="description"]').val()
    ,
      (error, result) =>
        if error
          console.error "Update discussion error", error
          alert "Update discussion error: #{error.reason or error}"
          return

        FlowRouter.go 'Discussion.display',
          _id: @currentDiscussionId()

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
