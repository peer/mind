class Discussion.ListComponent extends UIComponent
  @register 'Discussion.ListComponent'

  onCreated: ->
    super

    @showClosedDiscussions = new ReactiveField false

    @canNew = new ComputedField =>
      User.hasPermission User.PERMISSIONS.DISCUSSION_NEW

    @subscribe 'Meeting.list'
    @subscribe 'Discussion.list'

  onRendered: ->
    super

    footerComponent = @constructor.getComponent 'FooterComponent'

    @autorun (computation) =>
      if @canNew()
        footerComponent.setFixedButton 'Discussion.ListComponent.FixedButton'
      else
        footerComponent.setFixedButton null

    footerComponent.fixedButtonDataContext null

  onDestroyed: ->
    super

    footerComponent = @constructor.getComponent 'FooterComponent'
    footerComponent.removeFixedButton()

  discussionsWithoutMeeting: ->
    Discussion.documents.find _.extend(@showClosedDiscussionsQuery(),
      # Or discussions which are not part of any meeting which is being shown.
      'meetings._id':
        $nin: @meetings().map((meeting, i, cursor) => meeting._id)
    ),
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

    Discussion.documents.find _.extend(@showClosedDiscussionsQuery(),
      _id:
        $in: _.pluck discussions, '_id'
    ),
      sort: (a, b) =>
        order[a._id] - order[b._id]

  meetings: ->
    Meeting.documents.find @showPastMeetingsQuery(),
      sort:
        # The newest first.
        startAt: -1

  onShowClosedDiscussions: (event) ->
    event.preventDefault()

    @showClosedDiscussions @$('[name="show-discussions"]').is(':checked')

  showClosedDiscussionsQuery: ->
    if @showClosedDiscussions()
      {}
    else
      status:
        $in: [Discussion.STATUS.OPEN, Discussion.STATUS.MOTIONS, Discussion.STATUS.VOTING]

  showPastMeetingsQuery: ->
    if @showClosedDiscussions()
      {}
    else
      endAt:
        $gte: new Date()

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

class Discussion.ListComponent.FixedButton extends UIComponent
  @register 'Discussion.ListComponent.FixedButton'

FlowRouter.route '/',
  name: 'Discussion.list'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Discussion.ListComponent'

    share.PageTitle "Discussions"
