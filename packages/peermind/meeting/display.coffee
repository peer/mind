class Meeting.DisplayComponent extends Meeting.OneComponent
  @register 'Meeting.DisplayComponent'

  mixins: ->
    super.concat share.ExpandableMixin

  onCreated: ->
    super

    @autorun (computation) =>
      meetingId = @currentMeetingId()
      @subscribe 'Meeting.discussion', meetingId if meetingId

    @currentMeetingDiscussions = new ComputedField =>
      discussions = Meeting.documents.findOne(@currentMeetingId(),
        fields:
          'discussions.discussion._id': 1
          'discussions.order': 1
        transform: null
      )?.discussions

      return [] unless discussions

      discussions = _.sortBy discussions, 'order'

      (_id: item.discussion._id, order: item.order for item in discussions)
    ,
      EJSON.equals

  discussions: ->
    discussions = @currentMeetingDiscussions()

    order = {}
    for discussion in discussions
      order[discussion._id] = discussion.order

    Discussion.documents.find
      _id:
        $in: _.pluck discussions, '_id'
    ,
      sort: (a, b) ->
        order[a._id] - order[b._id]

  expandableEventData: ->
    data = @meeting()

    _id: data._id
    _type: data.constructor.Meta._name

class Meeting.EditButton extends UIComponent
  @register 'Meeting.EditButton'

class Meeting.DiscussionsListComponent extends UIComponent
  @register 'Meeting.DiscussionsListComponent'

  onRendered: ->
    super

    @$('.collection').sortable
      axis: 'y'
      handle: '.handle'
      items: '.collection-item'
      update: (event, ui) =>
        $currentItem = ui.item
        $prevItem = $currentItem.prev('.collection-item')
        $nextItem = $currentItem.next('.collection-item')

        discussions = @currentMeetingDiscussions()

        order = {}
        for discussion in discussions
          order[discussion._id] = discussion.order

        if not $prevItem.length and $nextItem.length
          nextComponent = UIComponent.getComponentForElement $nextItem.get(0)
          newOrder = order[nextComponent.data()._id] - 1
        else if not $nextItem.length and $prevItem.length
          prevComponent = UIComponent.getComponentForElement $prevItem.get(0)
          newOrder = order[prevComponent.data()._id] + 1
        else if $nextItem.length and $prevItem.length
          nextComponent = UIComponent.getComponentForElement $nextItem.get(0)
          prevComponent = UIComponent.getComponentForElement $prevItem.get(0)
          newOrder = (order[nextComponent.data()._id] + order[prevComponent.data()._id]) / 2
        else
          return

        currentComponent =  UIComponent.getComponentForElement $currentItem.get(0)

        Meteor.call 'Meeting.discussionOrder', @currentMeetingId(), currentComponent.data()._id, newOrder, (error, result) =>
          if error
            console.error "Discussion order error", error
            alert "Discussion order error: #{error.reason or error}"
            return

          # TODO: If result is 0, then maybe what you see ordered is not really what is stored in the database.
          #       We should rerender what is shown.

    @autorun (computation) =>
      # Register dependency.
      @discussions().fetch()

      Tracker.afterFlush =>
        @$('.collection').sortable('refresh')

  currentMeetingId: (args...) ->
    @callAncestorWith 'currentMeetingId', args...

  currentMeetingDiscussions: (args...) ->
    @callAncestorWith 'currentMeetingDiscussions', args...

  discussions: (args...) ->
    @callAncestorWith 'discussions', args...

class Meeting.DiscussionsListItemComponent extends UIComponent
  @register 'Meeting.DiscussionsListItemComponent'

  displayLength: ->
    meeting = Meeting.documents.findOne
      _id: @currentMeetingId()
      'discussions.discussion._id': @data()._id
    ,
      fields:
        'discussions.discussion._id': 1
        'discussions.length': 1
      transform: null

    discussion = null
    for d in meeting?.discussions or [] when d.discussion._id is @data()._id
      discussion = d
      break

    return unless discussion

    if discussion.length
      @pluralize discussion.length, "minute"
    else if @canEdit()
      "Set length"

  currentMeetingId: (args...) ->
    @callAncestorWith 'currentMeetingId', args...

  canEdit: (args...) ->
    @callAncestorWith 'canEdit', args...

  onClick: (event) ->
    event.preventDefault()

    length = prompt "Please enter new discussion length in minutes."

    return unless length

    length = parseInt length

    return unless _.isFinite length

    Meteor.call 'Meeting.discussionLength', @currentMeetingId(), @data()._id, length, (error, result) =>
      if error
        console.error "Discussion length error", error
        alert "Discussion length error: #{error.reason or error}"
        return

      # TODO: Should we check the result and if it is not expected show an error instead?

FlowRouter.route '/meeting/:_id',
  name: 'Meeting.display'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Meeting.DisplayComponent'

    # We set PageTitle after we get meeting title.
