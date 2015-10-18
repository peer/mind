class Meeting.ListComponent extends UIComponent
  @register 'Meeting.ListComponent'

FlowRouter.route '/',
  name: 'meeting.list'
  action: (params, queryParams) ->
    BlazeLayout.render 'LayoutComponent',
      main: 'Meeting.ListComponent'
