class Meeting.DisplayComponent extends Meeting.OneComponent
  @register 'Meeting.DisplayComponent'

  mixins: ->
    super.concat share.ExpandableMixin

  onCreated: ->
    super

    @autorun (computation) =>
      meetingId = @currentMeetingId()
      @subscribe 'Meeting.discussion', meetingId if meetingId

    @currentMeetingDiscussionsIds = new ComputedField =>
      _.pluck _.pluck(Meeting.documents.findOne(@currentMeetingId(),
        fields:
          discussions: 1
        transform: null
      )?.discussions or [], 'discussion'), '_id'
    ,
      EJSON.equals

  discussions: ->
    ids = @currentMeetingDiscussionsIds()

    Discussion.documents.find
      _id:
        $in: ids
    ,
      sort:
        order: 1

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
