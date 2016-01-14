class Meeting.ListComponent extends UIComponent
  @register 'Meeting.ListComponent'

  onCreated: ->
    super

    @canNew = new ComputedField =>
      # TODO: Allow only to those in "meeting" role, which should be a sub-role of "moderator" role.
      Roles.userIsInRole Meteor.userId(), ['moderator']

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
