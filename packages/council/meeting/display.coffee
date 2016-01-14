class Meeting.DisplayComponent extends Meeting.OneComponent
  @register 'Meeting.DisplayComponent'

  mixins: ->
    super.concat share.ExpandableMixin

  onCreated: ->
    super

    @autorun (computation) =>
      meetingId = @currentMeetingId()
      @subscribe 'Meeting.discussion', meetingId if meetingId

  discussions: ->
    Discussion.documents.find
      'meetings._id': @currentMeetingId()
    ,
      sort:
        # The newest first.
        createdAt: -1

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
