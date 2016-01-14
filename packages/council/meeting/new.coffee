class Meeting.NewComponent extends UIComponent
  @register 'Meeting.NewComponent'

  onCreated: ->
    super

    @canNew = new ComputedField =>
      # TODO: Allow only to those in "meeting" role, which should be a sub-role of "moderator" role.
      Roles.userIsInRole Meteor.userId(), ['moderator']

  onRendered: ->
    # TODO: Check why it does not enable every time?
    # TODO: Enable when know how to get the value.
    #@$('.datepicker').pickadate()

  events: ->
    super.concat
      'submit .meeting-new': @onSubmit

  constructDatetime: (date, time) ->
    # TODO: Make a warning or something?
    throw new Error "Both date and time fields are required together." if (date and not time) or (time and not date)

    return null unless date and time

    moment("#{date} #{time}", 'YYYY-MM-DD HH:mm').toDate()

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

        FlowRouter.go 'Meeting.display',
          _id: documentId

FlowRouter.route '/meeting/new',
  name: 'Meeting.new'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Meeting.NewComponent'

    share.PageTitle "New Meeting"
