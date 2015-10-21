class Discussion.ListComponent extends UIComponent
  @register 'Discussion.ListComponent'

  onCreated: ->
    super

    @canNew = new ComputedField =>
      !!Meteor.userId()

    @subscribe 'Meeting.list'
    @subscribe 'Discussion.list'

  discussionsWithoutMeeting: ->
    Discussion.documents.find
      # Discussions which do not have even the first meeting list item.
      'meetings.0':
        $exists: false

class Discussion.ListItemComponent extends UIComponent
  @register 'Discussion.ListItemComponent'

FlowRouter.route '/',
  name: 'Discussion.list'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Discussion.ListComponent'

    share.PageTitle "Discussions"
