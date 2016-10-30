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

  constructor: (personalized) ->
    personalized = false if personalized instanceof Spacebars.kw

    @personalized = personalized

  onCreated: ->
    super

    PAGE_SIZE = 50

    @activityLimit = new ReactiveField PAGE_SIZE
    @showLoading = new ReactiveField 0
    @showFinished = new ReactiveField 0
    @distanceToDocumentBottom = new ReactiveField null

    @activityHandle = @subscribe 'Activity.list', @personalized

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

      if activityCount is allCount and @distanceToDocumentBottom() is 0
        Tracker.nonreactive =>
          @showFinished @showFinished() + 1

          Meteor.setTimeout =>
            @showFinished @showFinished() - 1
          ,
            3000 # ms

    @_eventHandlerId = Random.id()

    $window = $(window)
    $document = $(document)

    $window.on "scroll.peermind.#{@_eventHandlerId}", _.throttle (event) =>
      windowHeight =  $window.height()
      bottom = $window.scrollTop() + windowHeight

      distanceToDocumentBottom = $document.height() - bottom

      @distanceToDocumentBottom distanceToDocumentBottom

      # Increase limit only when beyond two window heights to the end, otherwise return.
      return if distanceToDocumentBottom > 2 * windowHeight

      # We use the number of rendered activity documents instead of current count of
      # Activity.documents.find(@activityHandle.scopeQuery()).count() because we care
      # what is really displayed.
      renderedActivityCount = 0
      for child in @childComponents Activity.ListItemComponent
        renderedActivityCount += child.data().combinedDocumentsCount ? 1

      pages = Math.floor(renderedActivityCount / PAGE_SIZE)

      if renderedActivityCount <= (pages + 0.5) * PAGE_SIZE
        @activityLimit (pages + 1) * PAGE_SIZE
      else
        @activityLimit (pages + 2) * PAGE_SIZE
    ,
      50 # ms

  onDestroyed: ->
    super

    $(window).off "scroll.peermind.#{@_eventHandlerId}"

  activities: ->
    documents = Activity.documents.find(@activityHandle.scopeQuery(),
      sort:
        # The newest first.
        timestamp: -1
    ).fetch()

    combinedDocuments = []

    for document in documents
      if combinedDocuments.length is 0
        combinedDocuments.push document
        continue

      previousDocument = combinedDocuments[combinedDocuments.length - 1]
      if previousDocument.type is document.type
        # If categories are not the same, do not combine documents.
        if previousDocument.data.point?.category and previousDocument.data.point.category isnt document.data.point.category
          combinedDocuments.push document
          continue

        # If both documents are for the same discussion, combine them.
        if previousDocument.data.discussion?._id and previousDocument.data.discussion._id is document.data.discussion._id
          # But not if it is a mention from different places.
          if previousDocument.type is 'mention' and ((previousDocument.data.comment and not document.data.comment) or (previousDocument.data.point and not document.data.point) or (previousDocument.data.motion and not document.data.motion))
            combinedDocuments.push document
            continue

          previousDocument.laterDocuments ?= []
          previousDocument.combinedDocumentsCount ?= 1
          previousDocument.laterDocuments.push document
          previousDocument.combinedDocumentsCount++
          continue

      # We show only a user-level activity if both are available for same motion, one direction.
      else if (previousDocument.type is 'competingMotionOpened' and document.type is 'motionOpened') or (previousDocument.type is 'votedMotionClosed' and document.type is 'motionClosed')
        if previousDocument.timestamp.valueOf() is document.timestamp.valueOf() and previousDocument.data.motion._id is document.data.motion._id
          # We skip this document.
          previousDocument.combinedDocumentsCount ?= 1
          previousDocument.combinedDocumentsCount++
          continue

      # We show only a user-level activity if both are available for same motion, the other direction.
      else if (previousDocument.type is 'motionOpened' and document.type is 'competingMotionOpened') or (previousDocument.type is 'motionClosed' and document.type is 'votedMotionClosed')
        if previousDocument.timestamp.valueOf() is document.timestamp.valueOf() and previousDocument.data.motion._id is document.data.motion._id
          # We remove the previous (last) document, so that only this document is added to combinedDocuments.
          previousDocument.combinedDocumentsCount ?= 1
          document.combinedDocumentsCount = previousDocument.combinedDocumentsCount
          document.combinedDocumentsCount++
          combinedDocuments.pop()

      combinedDocuments.push document

    combinedDocuments

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
