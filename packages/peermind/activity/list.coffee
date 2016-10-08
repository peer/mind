class Activity.ListComponent extends UIComponent
  @register 'Activity.ListComponent'

  onCreated: ->
    super

    PAGE_SIZE = 50

    @showPersonalizedActivity = new ReactiveField false
    @activityHandle = new ReactiveField null
    @activityLimit = new ReactiveField PAGE_SIZE

    @autorun (computation) =>
      @activityHandle @subscribe 'Activity.list', !!@currentUserId() and @showPersonalizedActivity()

    @autorun (computation) =>
      @activityHandle()?.setData 'limit', @activityLimit()

    @_eventHandlerId = Random.id()

    $window = $(window)
    $document = $(document)

    $window.on "scroll.peermind.#{@_eventHandlerId}", _.throttle (event) =>
      windowHeight =  $window.height()
      bottom = $window.scrollTop() + windowHeight

      # Increase limit only when beyond two window heights to the end.
      return if bottom < $document.height() - 2 * windowHeight

      handle = @activityHandle()

      return unless handle

      # We use the number of rendered activity documents instead of current count of
      # Activity.documents.find(handle.scopeQuery()).count() because we care what is really displayed.
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
    handle = @activityHandle()

    if handle
      documents = Activity.documents.find(handle.scopeQuery(),
        sort:
          # The newest first.
          timestamp: -1
      ).fetch()
    else
      documents = []

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

  onShowPersonalizedActivity: (event) ->
    event.preventDefault()

    @showPersonalizedActivity @$('[name="show-personalized"]').is(':checked')

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
