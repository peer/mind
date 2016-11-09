class Meeting.ListComponent extends UIComponent
  @register 'Meeting.ListComponent'

  onCreated: ->
    super

    @canNew = new ComputedField =>
      User.hasPermission User.PERMISSIONS.MEETING_NEW

    @subscribe 'Meeting.list'

  onRendered: ->
    super

    footerComponent = @constructor.getComponent 'FooterComponent'

    @autorun (computation) =>
      if @canNew()
        footerComponent.setFixedButton 'Meeting.ListComponent.FixedButton'
      else
        footerComponent.setFixedButton null

    footerComponent.fixedButtonDataContext null

  onDestroyed: ->
    super

    footerComponent = @constructor.getComponent 'FooterComponent'
    footerComponent.removeFixedButton()

  meetings: ->
    Meeting.documents.find {},
      sort:
        # The newest first.
        startAt: -1

class Meeting.ListItemComponent extends UIComponent
  @register 'Meeting.ListItemComponent'

  mixins: ->
    super.concat share.IsSeenMixin

  onRendered: ->
    super

    @autorun (computation) =>
      return unless @currentUserId()

      isSeen = @callFirstWith null, 'isSeen'
      return unless isSeen
      computation.stop()

      lastSeenMeeting = @currentUser(lastSeenMeeting: 1).lastSeenMeeting?.valueOf() or 0

      meetingCreatedAt = @data('createdAt').valueOf()

      return unless lastSeenMeeting < meetingCreatedAt

      Meteor.call 'Meeting.seen', @data()._id, (error, result) =>
        if error
          console.error "Meeting seen error", error
          return

  # Used by IsSeenMixin.
  isVisible: ->
    true

class Meeting.ListComponent.FixedButton extends UIComponent
  @register 'Meeting.ListComponent.FixedButton'

FlowRouter.route '/meeting',
  name: 'Meeting.list'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Meeting.ListComponent'

    share.PageTitle "Meetings"
