class Meeting.ListComponent extends UIComponent
  @register 'Meeting.ListComponent'

  onCreated: ->
    super

    @canNew = new ComputedField =>
      User.hasPermission User.PERMISSIONS.MEETING_NEW

    @subscribe 'Meeting.list'

  meetings: ->
    Meeting.documents.find {},
      sort:
        # The newest first.
        startAt: -1

class Meeting.ListItemComponent extends UIComponent
  @register 'Meeting.ListItemComponent'

FlowRouter.route '/meeting',
  name: 'Meeting.list'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Meeting.ListComponent'

    share.PageTitle "Meetings"
