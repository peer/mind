class Discussion.NewComponent extends UIComponent
  @register 'Discussion.NewComponent'

  onCreated: ->
    super

    @canNew = new ComputedField =>
      !!Meteor.userId()

  events: ->
    super.concat
      'submit .discussion-new': @onSubmit

  onSubmit: (event) ->
    event.preventDefault()

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

FlowRouter.route '/discussion/new',
  name: 'Discussion.new'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Discussion.NewComponent'

    share.PageTitle "New Discussion"
