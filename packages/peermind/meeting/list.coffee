class Meeting.ListComponent extends UIComponent
  @register 'Meeting.ListComponent'

  onCreated: ->
    super

    @canNew = new ComputedField =>
      User.hasPermission User.PERMISSIONS.MEETING_NEW

    @subscribe 'Meeting.list'

  onRendered: ->
    super

    footerComponent = @constructor.getComponent 'FooterComponent'

    @autorun (computation) =>
      if @canNew()
        footerComponent.fixedButtonComponent 'Meeting.ListComponent.FixedButton'
        footerComponent.fixedButtonDataContext null
      else
        footerComponent.fixedButtonComponent null
        footerComponent.fixedButtonDataContext null

  onDestroyed: ->
    super

    footerComponent = @constructor.getComponent 'FooterComponent'

    footerComponent.fixedButtonComponent null
    footerComponent.fixedButtonDataContext null

  meetings: ->
    Meeting.documents.find {},
      sort:
        # The newest first.
        startAt: -1

class Meeting.ListItemComponent extends UIComponent
  @register 'Meeting.ListItemComponent'

class Meeting.ListComponent.FixedButton extends UIComponent
  @register 'Meeting.ListComponent.FixedButton'

FlowRouter.route '/meeting',
  name: 'Meeting.list'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Meeting.ListComponent'

    share.PageTitle "Meetings"
