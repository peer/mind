class Activity.ListComponent extends UIComponent
  @register 'Activity.ListComponent'

  onCreated: ->
    @showPersonalizedActivity = new ComputedField =>
      FlowRouter.getQueryParam('personalized') is 'true'

  onShowPersonalizedActivity: (event) ->
    event.preventDefault()

    FlowRouter.go 'Activity.list', {},
      personalized: @$('[name="show-personalized"]').is(':checked')

  personalized: ->
    !!@currentUserId() and @showPersonalizedActivity()

  checked: ->
    checked: true if @showPersonalizedActivity()

class Activity.ListContentComponent extends UIComponent
  @register 'Activity.ListContentComponent'

  mixins: ->
    super.concat new share.InfiniteScrollingMixin Activity, Activity.ListItemComponent, @pageSize, @notifications

  constructor: (kwargs) ->
    super

    _.extend @, _.pick (kwargs?.hash or {}), 'personalized', 'pageSize', 'notifications'

    @pageSize ||= 50

  onCreated: ->
    super

    # Used by InfiniteScrollingMixin.
    @subscriptionHandle = @subscribe 'Activity.list', @personalized, @pageSize

  activities: ->
    Activity.combineActivities Activity.documents.find(@subscriptionHandle.scopeQuery(),
      sort:
        # The newest first.
        timestamp: -1
    ).fetch()

class Activity.ListContainerComponent extends UIComponent
  @register 'Activity.ListContainerComponent'

  constructor: (kwargs) ->
    super

    _.extend @, _.pick (kwargs?.hash or {}), 'notifications'

class Activity.ListItemComponent extends UIComponent
  @register 'Activity.ListItemComponent'

  mixins: ->
    super.concat share.IsSeenMixin

  constructor: (kwargs) ->
    super

    _.extend @, _.pick (kwargs?.hash or {}), 'notifications'

  onRendered: ->
    super

    component = @ancestorComponent Activity.ListContentComponent

    return unless component.personalized

    @autorun (computation) =>
      # It should not really be possible for personalized activity.
      return unless @currentUserId()

      isSeen = @callFirstWith null, 'isSeen'
      return unless isSeen
      computation.stop()

      lastSeenPersonalizedActivity = @currentUser(lastSeenPersonalizedActivity: 1).lastSeenPersonalizedActivity?.valueOf() or 0

      activityTimestamp = @data('timestamp').valueOf()

      return unless lastSeenPersonalizedActivity < activityTimestamp

      Meteor.call 'Activity.seenPersonalized', @data()._id, (error, result) =>
        if error
          console.error "Activity seen personalized error", error
          return

  # Used by IsSeenMixin.
  isVisible: ->
    component = @ancestorComponent('NotificationsComponent')
    return true unless component

    component.dropdownVisible()

  renderActivity: (parentComponent) ->
    parentComponent ?= @currentComponent()

    type = @data 'type'
    componentName = type.charAt(0).toUpperCase() + type.substring(1)

    component = @constructor.getComponent "Activity.ListItemComponent.#{componentName}"

    unless component
      console.error "Missing a component for activity type '#{type}'."
      return null

    component.renderComponent parentComponent

  icon: ->
    type = @data 'type'
    switch type
      when 'commentCreated' then 'comment'
      when 'pointCreated'
        switch @data 'data.point.category'
          when Point.CATEGORY.AGAINST then 'trending_down'
          when Point.CATEGORY.IN_FAVOR then "trending_up"
          when Point.CATEGORY.OTHER then "trending_flat"
      when 'motionCreated', 'motionOpened', 'competingMotionOpened', 'motionClosed', 'votedMotionClosed', 'motionWithdrawn' then 'gavel'
      when 'commentUpvoted', 'pointUpvoted', 'motionUpvoted' then 'thumb_up'
      when 'discussionCreated', 'discussionClosed' then 'bubble_chart'
      when 'meetingCreated' then 'event'
      when 'mention' then 'person'
      else
        console.error "Missing an icon for activity type '#{type}'."
        null

  link: ->
    type = @data 'type'
    switch type
      # TODO: Should we link directly to comments, points, motions, mentions, instead of just to a discussion?
      when 'commentCreated', 'pointCreated', 'motionCreated', 'motionOpened', \
        'competingMotionOpened', 'motionClosed', 'votedMotionClosed', 'motionWithdrawn', \
        'commentUpvoted', 'pointUpvoted', 'motionUpvoted', \
        'discussionCreated', 'discussionClosed', 'mention'
          FlowRouter.path 'Discussion.display', @data 'data.discussion'
      when 'meetingCreated'
          FlowRouter.path 'Meeting.display', @data 'data.meeting'
      else
        console.error "Missing an icon for activity type '#{type}'."
        null

class Activity.ListItemContainerComponent extends UIComponent
  @register 'Activity.ListItemContainerComponent'

  constructor: (kwargs) ->
    super

    _.extend @, _.pick (kwargs?.hash or {}), 'notifications'

  link: ->
    @parentComponent()?.link?()

class ActivityComponent extends UIComponent
  # We do not use "pluralize" but a custom method.
  count: (documents, singular, plural) ->
    if documents.length is 1
      singular
    else
      "#{documents.length} #{plural}"

  different: (path) ->
    first = @data path
    laterDocuments = @data('laterDocuments') or []

    all = [first].concat _.map laterDocuments, (doc) =>
      _.path doc, path

    _.uniq all, (doc) =>
      doc?._id

  notifications: ->
    if _.isFunction @parentComponent()?.notifications
      @parentComponent()?.notifications()
    else
      @parentComponent()?.notifications

  link: ->
    @parentComponent()?.link?()

class Activity.ListItemComponent.Author extends ActivityComponent
  @register 'Activity.ListItemComponent.Author'

  otherAuthors: ->
    authors = @different 'byUser'

    # We remove the first author.
    authors.shift()

    authors

  others: ->
    @otherAuthors().length - 1

class Activity.ListItemComponent.Link extends ActivityComponent
  @register 'Activity.ListItemComponent.Link'

class PointActivityComponent extends ActivityComponent
  category: ->
    switch @data 'data.point.category'
      when Point.CATEGORY.AGAINST then "against"
      when Point.CATEGORY.IN_FAVOR then "in favor"
      when Point.CATEGORY.OTHER then ""

class Activity.ListItemComponent.CommentCreated extends ActivityComponent
  @register 'Activity.ListItemComponent.CommentCreated'

class Activity.ListItemComponent.PointCreated extends PointActivityComponent
  @register 'Activity.ListItemComponent.PointCreated'

class Activity.ListItemComponent.MotionCreated extends ActivityComponent
  @register 'Activity.ListItemComponent.MotionCreated'

class Activity.ListItemComponent.CommentUpvoted extends ActivityComponent
  @register 'Activity.ListItemComponent.CommentUpvoted'

class Activity.ListItemComponent.PointUpvoted extends PointActivityComponent
  @register 'Activity.ListItemComponent.PointUpvoted'

class Activity.ListItemComponent.MotionUpvoted extends ActivityComponent
  @register 'Activity.ListItemComponent.MotionUpvoted'

class Activity.ListItemComponent.DiscussionCreated extends ActivityComponent
  @register 'Activity.ListItemComponent.DiscussionCreated'

class Activity.ListItemComponent.DiscussionClosed extends ActivityComponent
  @register 'Activity.ListItemComponent.DiscussionClosed'

class Activity.ListItemComponent.MeetingCreated extends ActivityComponent
  @register 'Activity.ListItemComponent.MeetingCreated'

class Activity.ListItemComponent.MotionOpened extends ActivityComponent
  @register 'Activity.ListItemComponent.MotionOpened'

class Activity.ListItemComponent.CompetingMotionOpened extends ActivityComponent
  @register 'Activity.ListItemComponent.CompetingMotionOpened'

class Activity.ListItemComponent.MotionClosed extends ActivityComponent
  @register 'Activity.ListItemComponent.MotionClosed'

class Activity.ListItemComponent.VotedMotionClosed extends ActivityComponent
  @register 'Activity.ListItemComponent.VotedMotionClosed'

class Activity.ListItemComponent.MotionWithdrawn extends ActivityComponent
  @register 'Activity.ListItemComponent.MotionWithdrawn'

class Activity.ListItemComponent.Mention extends ActivityComponent
  @register 'Activity.ListItemComponent.Mention'

FlowRouter.route '/activity',
  name: 'Activity.list'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Activity.ListComponent'

    share.PageTitle "Activity"
