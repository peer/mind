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
      _.pluck Meeting.documents.findOne(@currentMeetingId(),
        fields:
          discussions: 1
        transform: null
      )?.discussions or [], '_id'
    ,
      EJSON.equals

  discussions: ->
    ids = @currentMeetingDiscussions()

    idToIndex = {}
    for id, i in ids
      idToIndex[id] = i

    cursor = Discussion.documents.find
      _id:
        $in: ids

    # TODO: Remove this hack when this pull request is merged in: https://github.com/meteor/meteor/pull/6008
    cursor.sorter =
      getComparator: ->
        (a, b) ->
          # Sorting in the order in which IDs are listed.
          idToIndex[a._id] - idToIndex[b._id]

    cursor

  expandableEventData: ->
    data = @meeting()

    _id: data._id
    _type: data.constructor.Meta._name

class Meeting.EditButton extends UIComponent
  @register 'Meeting.EditButton'

class Meeting.DiscussionsListItemComponent extends UIComponent
  @register 'Meeting.DiscussionsListItemComponent'

FlowRouter.route '/meeting/:_id',
  name: 'Meeting.display'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Meeting.DisplayComponent'

    # We set PageTitle after we get meeting title.
