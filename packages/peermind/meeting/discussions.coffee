class Meeting.ListDiscussionsComponent extends Meeting.OneComponent
  @register 'Meeting.ListDiscussionsComponent'

  onCreated: ->
    super

    @subscribe 'Discussion.list', true

  onRendered: ->
    super

    footerComponent = @constructor.getComponent 'FooterComponent'

    @autorun (computation) =>
      if @canEdit()
        footerComponent.setFixedButton 'Meeting.ListDiscussionsComponent.FixedButton'
      else
        footerComponent.setFixedButton null

    @autorun (computation) =>
      footerComponent.fixedButtonDataContext @meeting()

  onDestroyed: ->
    super

    footerComponent = @constructor.getComponent 'FooterComponent'
    footerComponent.removeFixedButton()

  discussions: ->
    Discussion.documents.find {},
      sort:
        # The newest first.
        createdAt: -1

class Meeting.ListDiscussionsItemComponent extends UIComponent
  @register 'Meeting.ListDiscussionsItemComponent'

  meeting: ->
    @ancestorComponent(Meeting.ListDiscussionsComponent).meeting()

  checked: ->
    meetingDiscussions = @meeting()?.discussions

    checked: true if _.findWhere _.pluck(meetingDiscussions, 'discussion'), _id: @data()._id

  onChange: (event) ->
    event.preventDefault()

    Meteor.call 'Meeting.toggleDiscussion', @meeting()._id, @data()._id, @$('input').is(':checked'), (error, result) =>
      if error
        console.error "Discussion toggle error", error
        alert "Discussion toggle error: #{error.reason or error}"
        return

      # TODO: If result is 0, then maybe what you see checked is not really what is stored in the database.
      #       We should rerender what is shown.

  closed: ->
    'closed' if @data()?.status in [Discussion.STATUS.CLOSED, Discussion.STATUS.PASSED]

  otherMeetings: ->
    (meeting for meeting in @data().meetings when meeting._id isnt @meeting()?._id)

class Meeting.ListDiscussionsComponent.FixedButton extends UIComponent
  @register 'Meeting.ListDiscussionsComponent.FixedButton'

FlowRouter.route '/meeting/discussions/:_id',
  name: 'Meeting.discussions'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Meeting.ListDiscussionsComponent'

    # We set PageTitle after we get meeting title.
