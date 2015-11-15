class Discussion.ListComponent extends UIComponent
  @register 'Discussion.ListComponent'

  onCreated: ->
    super

    @canNew = new ComputedField =>
      # TODO: Allow only to those in "discussion" role, which should be a sub-role of "member" role.
      Roles.userIsInRole Meteor.userId(), 'member'

    @subscribe 'Meeting.list'
    @subscribe 'Discussion.list'

  discussionsWithoutMeeting: ->
    Discussion.documents.find
      # Discussions which do not have even the first meeting list item.
      'meetings.0':
        $exists: false
    ,
      sort:
        # The oldest first.
        createdAt: 1

class Discussion.ListItemComponent extends UIComponent
  @register 'Discussion.ListItemComponent'

FlowRouter.route '/',
  name: 'Discussion.list'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Discussion.ListComponent'

    share.PageTitle "Discussions"
