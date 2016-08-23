class Discussion.NewComponent extends UIComponent
  @register 'Discussion.NewComponent'

  onCreated: ->
    super

    @canNew = new ComputedField =>
      User.hasPermission User.PERMISSIONS.DISCUSSION_NEW

  onRendered: ->
    super

    Materialize.updateTextFields()

  events: ->
    super.concat
      'submit .discussion-new': @onSubmit

  onSubmit: (event) ->
    event.preventDefault()

    # TODO: We cannot use required for description input with trix.
    unless @hasDescription()
      # TODO: Use flash messages.
      alert "Description is required."
      return

    Meteor.call 'Discussion.new',
      title: @$('[name="title"]').val()
      description: @$('[name="description"]').val()
    ,
      (error, documentId) =>
        if error
          console.error "New discussion error", error
          alert "New discussion error: #{error.reason or error}"
          return

        FlowRouter.go 'Discussion.display',
          _id: documentId

  hasDescription: ->
    # We require description to have at least some text content or a figure.
    $description = $($.parseHTML(@$('[name="description"]').val()))
    $description.text() or $description.has('figure').length

FlowRouter.route '/discussion/new',
  name: 'Discussion.new'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Discussion.NewComponent'

    share.PageTitle "New Discussion"
