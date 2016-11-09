# Abstract class.
class Meeting.OneComponent extends UIComponent
  mixins: ->
    super.concat share.IsSeenMixin

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

  onRendered: ->
    super

    @autorun (computation) =>
      return unless @currentUserId()

      return unless @subscriptionsReady()

      return unless @meeting()

      isSeen = @callFirstWith null, 'isSeen'
      return unless isSeen
      computation.stop()

      lastSeenMeeting = @currentUser(lastSeenMeeting: 1).lastSeenMeeting?.valueOf() or 0

      meetingCreatedAt = @meeting().createdAt.valueOf()

      return unless lastSeenMeeting < meetingCreatedAt

      Meteor.call 'Meeting.seen', @currentMeetingId(), (error, result) =>
        if error
          console.error "Meeting seen error", error
          return

  # Used by IsSeenMixin.
  isVisible: ->
    true

  meeting: ->
    Meeting.documents.findOne @currentMeetingId()

  notFound: ->
    @subscriptionsReady() and not @meeting()

  contributeUsersForMention: ->
    users = []

    if author = @meeting()?.author
      users.push author

    users
