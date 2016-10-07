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
      @meeting() and (User.hasPermission(User.PERMISSIONS.MEETING_UPDATE) or (User.hasPermission(User.PERMISSIONS.MEETING_UPDATE_OWN) and (Meteor.userId() is @meeting().author._id)))

  meeting: ->
    Meeting.documents.findOne @currentMeetingId()

  notFound: ->
    @subscriptionsReady() and not @meeting()

  contributeUsersForMention: ->
    users = []

    if author = @meeting()?.author
      users.push author

    users
