class Meeting.NewComponent extends UIComponent
  @register 'Meeting.NewComponent'

  onCreated: ->
    super

    @canNew = new ComputedField =>
      User.hasPermission User.PERMISSIONS.MEETING_NEW

  onRendered: ->
    Materialize.updateTextFields()

    # TODO: Check why it does not enable every time?
    # TODO: Enable when know how to get the value.
    #@$('.datepicker').pickadate()

  events: ->
    super.concat
      'submit .meeting-new': @onSubmit

  onSubmit: (event) ->
    event.preventDefault()

    Meteor.call 'Meeting.new',
      title: @$('[name="title"]').val()
      startAt: @constructDatetime @$('[name="start-date"]').val(), @$('[name="start-time"]').val()
      endAt: @constructDatetime @$('[name="end-date"]').val(), @$('[name="end-time"]').val()
      description: @$('[name="description"]').val()
    ,
      (error, documentId) =>
        if error
          console.error "New meeting error", error
          alert "New meeting error: #{error.reason or error}"
          return

        for component in @childComponents 'EditorComponent'
          component.clearStoredState()
 
        FlowRouter.go 'Meeting.display',
          _id: documentId

FlowRouter.route '/meeting/new',
  name: 'Meeting.new'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Meeting.NewComponent'

    share.PageTitle "New Meeting"
