class Discussion.DisplayComponent extends Discussion.OneComponent
  @register 'Discussion.DisplayComponent'

  @displayTab: ->
    "Description"

  onRendered: ->
    super

    footerComponent = @constructor.getComponent 'FooterComponent'

    @autorun (computation) =>
      if @canClose()
        footerComponent.setFixedButton 'Discussion.DisplayComponent.FixedButton'
      else
        footerComponent.setFixedButton null

    @autorun (computation) =>
      footerComponent.fixedButtonDataContext @discussion()

  onDestroyed: ->
    super

    footerComponent = @constructor.getComponent 'FooterComponent'
    footerComponent.removeFixedButton()

  renderMetadataTimestamp: (parentComponent, metadataComponent) ->
    Discussion.MetadataTimestampComponent.renderComponent parentComponent

class Discussion.MetadataTimestampComponent extends UIComponent
  @register 'Discussion.MetadataTimestampComponent'

class Discussion.EditFormComponent extends UIComponent
  @register 'Discussion.EditFormComponent'

  onRendered: ->
    super

    Materialize.updateTextFields()

    Tracker.afterFlush =>
      # A bit of mangling to get cursor to focus at the end of the text.
      $title = @$('[name="title"]')
      title = $title.val()
      $title.focus().val('').val(title)

  canOnlyEdit: (args...) ->
    @callAncestorWith 'canOnlyEdit', args...

  canEditClosed: (args...) ->
    @callAncestorWith 'canEditClosed', args...

class Discussion.DisplayComponent.FixedButton extends UIComponent
  @register 'Discussion.DisplayComponent.FixedButton'

class Discussion.FollowingDropdown extends UIComponent
  @register 'Discussion.FollowingDropdown'

  onCreated: ->
    super

    @dialogOpened = new ReactiveField false

    @_eventHandlerId = Random.id()

    $(document).on "click.peermind.#{@_eventHandlerId}", (event) =>
      return unless @isRendered() and @dialogOpened()

      dropdown = @$('.dropdown-content').get(0)

      return unless dropdown

      return if dropdown is event.target or $.contains(dropdown, event.target)

      @dialogOpened false

  onDestroyed: ->
    super

    $(document).off "click.peermind.#{@_eventHandlerId}"

  discussion: ->
    @callAncestorWith 'discussion'

  icon: ->
    follower = @discussion()?.followerDocument Meteor.userId()

    if Discussion.isFollower follower
      'bookmark'
    else
      'bookmark_border'

  label: ->
    follower = @discussion()?.followerDocument Meteor.userId()

    if Discussion.isFollowing follower?.reason
      "Following"
    else if Discussion.isOnlyMentions follower?.reason
      "Only mentions"
    else if Discussion.isIgnoring follower?.reason
      "Ignoring"
    else if Discussion.isNotFollowing follower?.reason
      "Not following"

  active: (type) ->
    follower = @discussion()?.followerDocument Meteor.userId()

    classes = ['active', 'selected']

    if type is 'following' and Discussion.isFollowing follower?.reason
      return classes

    if type is 'mentions' and Discussion.isOnlyMentions follower?.reason
      return classes

    if type is 'ignoring' and Discussion.isIgnoring follower?.reason
      return classes

    if type is 'not-following' and Discussion.isNotFollowing follower?.reason
      return classes

  reason: ->
    follower = @discussion()?.followerDocument Meteor.userId()

    if follower?.reason is Discussion.REASON.AUTHOR
      "you are its author"
    else if follower?.reason is Discussion.REASON.MENTIONED
      "you were mentioned in it"
    else if follower?.reason is Discussion.REASON.PARTICIPATED
      "you participated in it"

  onButtonClick: (event) ->
    event.preventDefault()

    @dialogOpened true

  onOptionClick: (event, type) ->
    event.preventDefault()

    Meteor.call 'Discussion.follow', @discussion()._id, type, (error, result) =>
      if error
        console.error "Follow error", error
        alert "Follow error: #{error.reason or error}"
        return

      @dialogOpened false

FlowRouter.route '/discussion/:_id',
  name: 'Discussion.display'
  action: (params, queryParams) ->
    BlazeLayout.render 'ColumnsLayoutComponent',
      main: 'Discussion.DisplayComponent'
      first: 'Comment.ListComponent'
      second: 'Point.ListComponent'
      third: 'Motion.ListComponent'

    # We set PageTitle after we get discussion title.
