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

  constructor: (kwargs) ->
    _.extend @, _.pick (kwargs?.hash or {}), 'personalized', 'pageSize'

    @pageSize ||= 50
    
  onCreated: ->
    super

    @activityLimit = new ReactiveField @pageSize
    @showLoading = new ReactiveField 0
    @showFinished = new ReactiveField 0
    @distanceToScrollParentBottom = new ReactiveField null, true

    @activityHandle = @subscribe 'Activity.list', @personalized, @pageSize

    @autorun (computation) =>
      @activityHandle.setData 'limit', @activityLimit()

      Tracker.nonreactive =>
        @showLoading @showLoading() + 1

    @autorun (computation) =>
      showLoading = @showLoading()

      return unless showLoading

      return unless @activityHandle.ready()

      activityCount = Activity.documents.find(@activityHandle.scopeQuery()).count()
      allCount = @activityHandle.data('count') or 0

      if activityCount is allCount or activityCount is @activityLimit()
        @showLoading showLoading - 1

    @autorun (computation) =>
      return unless @activityHandle.ready()

      allCount = @activityHandle.data('count') or 0
      activityCount = Activity.documents.find(@activityHandle.scopeQuery()).count()

      # Only when scrolling down and we reach scroll parent bottom we display finished message.
      if activityCount is allCount and @distanceToScrollParentBottom() <= 0 and @distanceToScrollParentBottom() < @distanceToScrollParentBottom.previous()
        Tracker.nonreactive =>
          @showFinished @showFinished() + 1

          Meteor.setTimeout =>
            @showFinished @showFinished() - 1
          ,
            3000 # ms

  onRendered: ->
    super

    @_eventHandlerId = Random.id()

    $listWrapper = @$('.list-wrapper')
    @$scrollParent = $listWrapper.scrollParent()

    @$scrollParent = $(window) if @$scrollParent.get(0) is document

    @handleScrolling = _.throttle (event) =>
      # If list is not visible, we cannot compute current height to know how much more we should load.
      return unless $listWrapper.is(':visible')

      if @$scrollParent.get(0) is window
        listWrapperTopInsideScrollParent = $listWrapper.offset().top
      else
        listWrapperTopInsideScrollParent = ($listWrapper.offset().top + @$scrollParent.scrollTop()) - @$scrollParent.offset().top

      scrollParentHeight = @$scrollParent.height()
      # If max-height is set on a scroll parent element, we want to expand the content all
      # the way until scroll parent element is full of content, if it is not already.
      # Window cannot have CSS and jQuery css method fails on it.
      scrollParentHeight = Math.max(scrollParentHeight, parseInt(@$scrollParent.css('max-height')) or 0) if @$scrollParent.get(0) isnt window
      bottom = @$scrollParent.scrollTop() + scrollParentHeight

      contentHeight = $listWrapper.prop('scrollHeight')

      distanceToScrollParentBottom = (contentHeight + listWrapperTopInsideScrollParent) - bottom

      @distanceToScrollParentBottom distanceToScrollParentBottom

      # Increase limit only when beyond two window heights to the end, otherwise return.
      return if distanceToScrollParentBottom > 2 * scrollParentHeight

      # We use the number of rendered activity documents instead of current count of
      # Activity.documents.find(@activityHandle.scopeQuery()).count() because we care
      # what is really displayed.
      renderedActivityCount = 0
      for child in @childComponents Activity.ListItemComponent
        renderedActivityCount += child.data().combinedDocumentsCount ? 1

      pages = Math.floor(renderedActivityCount / @pageSize)

      oldActivityLimit = @activityLimit()

      if renderedActivityCount <= (pages + 0.5) * @pageSize
        @activityLimit (pages + 1) * @pageSize
      else
        @activityLimit (pages + 2) * @pageSize

      # We want new limit to get into the effect as soon as possible so that we immediately show
      # loading feedback and start getting new data. So we flush manually. Otherwise sometimes there
      # were delays between change to activityLimit and autorun setting limit on activityHandle.
      Tracker.flush() if oldActivityLimit isnt @activityLimit()
    ,
      100 # ms

    @$scrollParent.on "scroll.peermind.#{@_eventHandlerId}", @handleScrolling

    @autorun (computation) =>
      return unless @activityHandle.ready()

      # Every time the number of documents change, check if we should load even more.
      # This handles also loading all necessary documents to fill the scroll parent.
      Activity.documents.find(@activityHandle.scopeQuery()).count()

      # We want to wait for documents to render.
      Tracker.afterFlush =>
        # We cannot call it directly from inside the autorun because inside handleScrolling we call Tracker.flush.
        Meteor.defer @handleScrolling

  onDestroyed: ->
    super

    @$scrollParent.off "scroll.peermind.#{@_eventHandlerId}"

  activities: ->
    Activity.combineActivities Activity.documents.find(@activityHandle.scopeQuery(),
      sort:
        # The newest first.
        timestamp: -1
    ).fetch()

  insertDOMElement: (parent, node, before, next) ->
    next ?= =>
      super parent, node, before
      true

    $node = $(node)
    if $node.hasClass 'finished-loading'
      next()
      $node.velocity 'fadeIn',
        duration: 'slow'
        queue: false

    else
      next()

    # We are handling it.
    true

  removeDOMElement: (parent, node, next) ->
    next ?= =>
      super parent, node
      true

    $node = $(node)
    if $node.hasClass 'finished-loading'
      # We can call just "stop" because it does not matter that we have not animated insertion
      # to the end and we have no "complete" callback on insertion as well to care about.
      $node.velocity('stop').velocity 'fadeOut',
        duration: 'slow'
        queue: false
        complete: (element) =>
          next()

    else
      next()

    # We are handling it.
    true

class Activity.ListItemComponent extends UIComponent
  @register 'Activity.ListItemComponent'

  renderActivity: (parentComponent) ->
    parentComponent ?= @currentComponent()

    type = @data 'type'
    componentName = type.charAt(0).toUpperCase() + type.substring(1)

    component = @constructor.getComponent "Activity.ListItemComponent.#{componentName}"

    return null unless component

    component.renderComponent parentComponent

  icon: ->
    switch @data 'type'
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

class Activity.ListItemComponent.Author extends ActivityComponent
  @register 'Activity.ListItemComponent.Author'

  otherAuthors: ->
    authors = @different 'byUser'

    # We remove the first author.
    authors.shift()

    authors

  others: ->
    @otherAuthors().length - 1

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
