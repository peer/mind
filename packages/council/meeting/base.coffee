# Abstract class.
class Meeting.OneComponent extends UIComponent
  onCreated: ->
    super

    @currentMeetingId = new ComputedField =>
      FlowRouter.getParam '_id'

    @autorun (computation) =>
      meetingId = @currentMeetingId()
      @subscribe 'Meeting.one', meetingId if meetingId

    @autorun (computation) =>
      return unless @subscriptionsReady()

      meeting = Meeting.documents.findOne @currentMeetingId(),
        fields:
          title: 1

      if meeting
        share.PageTitle meeting.title
      else
        share.PageTitle "Not found"

    @canEdit = new ComputedField =>
      @meeting() and (Roles.userIsInRole(Meteor.userId(), 'moderator') or (Meteor.userId() is @meeting().author._id))

  meeting: ->
    Meeting.documents.findOne @currentMeetingId()

  notFound: ->
    @subscriptionsReady() and not @meeting()
