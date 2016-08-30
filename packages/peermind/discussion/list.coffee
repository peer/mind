class Discussion.ListComponent extends UIComponent
  @register 'Discussion.ListComponent'

  onCreated: ->
    super

    @canNew = new ComputedField =>
      User.hasPermission User.PERMISSIONS.DISCUSSION_NEW

    @subscribe 'Meeting.list'
    @subscribe 'Discussion.list'

  discussionsWithoutMeeting: ->
    Discussion.documents.find
      # Discussions which do not have even the first meeting list item.
      'meetings.0':
        $exists: false
    ,
      sort:
        # The newest first.
        createdAt: -1

  discussionsForMeeting: (meeting) ->
    meeting = null if meeting instanceof Spacebars.kw

    discussions = meeting?.discussions or []
    discussions = _.sortBy discussions, 'order'
    discussions = (_id: item.discussion._id, order: item.order for item in discussions)

    order = {}
    for discussion in discussions
      order[discussion._id] = discussion.order

    Discussion.documents.find
      _id:
        $in: _.pluck discussions, '_id'
    ,
      sort: (a, b) =>
        order[a._id] - order[b._id]

  meetings: ->
    Meeting.documents.find {},
      sort:
        # The newest first.
        startAt: -1

class Discussion.ListItemComponent extends UIComponent
  @register 'Discussion.ListItemComponent'

  displayStatus: ->
    data = @data()
    if data?.status is Discussion.STATUS.DRAFT
      "drafting discussion"
    else if data?.status is Discussion.STATUS.OPEN
      "discussion"
    else if data?.status is Discussion.STATUS.MOTIONS
      "drafting motions"
    else if data?.status is Discussion.STATUS.VOTING
      "voting open"
    else if data?.status is Discussion.STATUS.CLOSED
      "closed"
    else if data?.status is Discussion.STATUS.PASSED
      "passed"

  closed: ->
    'closed' if @data()?.status in [Discussion.STATUS.CLOSED, Discussion.STATUS.PASSED]

FlowRouter.route '/',
  name: 'Discussion.list'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Discussion.ListComponent'

    share.PageTitle "Discussions"
