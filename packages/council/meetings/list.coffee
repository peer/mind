class Meetings.ListComponent extends BlazeComponent
  @register 'Meetings.ListComponent'

FlowRouter.route '/',
  name: 'meetings.list'
  action: (params, queryParams) ->
    BlazeLayout.render 'LayoutComponent',
      main: 'Meetings.ListComponent'
