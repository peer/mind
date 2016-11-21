# subscriptionHandle has to be defined on the component for this mixin.
class share.InfiniteScrollingMixin extends UIMixin
  constructor: (@subscriptionDocument, @subscriptionComponent, @subscriptionPageSize, @slideInsteadFade=false) ->

  onCreated: ->
    super

    @_eventHandlerId = Random.id()

    @subscriptionLimit = new ReactiveField @subscriptionPageSize
    @showLoading = new ReactiveField 0
    @showFinished = new ReactiveField 0
    @distanceToScrollParentBottom = new ReactiveField null, true

    @_subscriptionHandle = @callFirstWith null, 'subscriptionHandle'

    @autorun (computation) =>
      @_subscriptionHandle.setData 'limit', @subscriptionLimit()

      Tracker.nonreactive =>
        @showLoading @showLoading() + 1

    @autorun (computation) =>
      showLoading = @showLoading()

      return unless showLoading

      return unless @_subscriptionHandle.ready()

      allCount = @_subscriptionHandle.data('count') or 0
      documentCount = @subscriptionDocument.documents.find(@_subscriptionHandle.scopeQuery()).count()

      if documentCount is allCount or documentCount is @subscriptionLimit()
        @showLoading showLoading - 1

    @autorun (computation) =>
      return unless @_subscriptionHandle.ready()

      allCount = @_subscriptionHandle.data('count') or 0
      documentCount = @subscriptionDocument.documents.find(@_subscriptionHandle.scopeQuery()).count()

      # Only when scrolling down and we reach scroll parent bottom we display finished loading feedback.
      if documentCount is allCount and @distanceToScrollParentBottom() <= 0 and @distanceToScrollParentBottom() < @distanceToScrollParentBottom.previous()
        Tracker.nonreactive =>
          @showFinished @showFinished() + 1

          Meteor.setTimeout =>
            @showFinished @showFinished() - 1
          ,
            3000 # ms

          # We want to immediately show finished loading feedback. So we flush manually.
          # We cannot call Tracker.flush directly from inside the autorun.
          # TODO: There are still occasionally delays (> 1 second) between scrolling to the bottom and finished loading feedback appearing.
          Meteor.defer Tracker.flush if @showFinished() is 1

  onRendered: ->
    super

    $listWrapper = @$('.list-wrapper')
    @$scrollParent = $listWrapper.scrollParent()

    @$scrollParent = $(window) if @$scrollParent.get(0) is document

    @handleScrolling = _.throttle (event) =>
      # If list is not visible, we cannot compute current height to know how much more we should load.
      return unless $listWrapper.is(':visible')

      {distanceToScrollParentBottom, scrollParentHeight} = @_distanceToScrollParentBottom()

      @distanceToScrollParentBottom distanceToScrollParentBottom

      # Increase limit only when beyond two window heights to the end, otherwise return.
      return if distanceToScrollParentBottom > 2 * scrollParentHeight

      # We use the number of rendered documents instead of current count of
      # @subscriptionDocument.documents.find(@_subscriptionHandle.scopeQuery()).count()
      # because we care what is really displayed.
      renderedDocumentCount = 0
      for child in @descendantComponents @subscriptionComponent
        renderedDocumentCount += child.data().combinedDocumentsCount ? 1

      pages = Math.floor(renderedDocumentCount / @subscriptionPageSize)

      oldSubscriptionLimit = @subscriptionLimit()

      if renderedDocumentCount <= (pages + 0.5) * @subscriptionPageSize
        @subscriptionLimit (pages + 1) * @subscriptionPageSize
      else
        @subscriptionLimit (pages + 2) * @subscriptionPageSize

      # We want new limit to get into the effect as soon as possible so that we immediately show
      # loading feedback and start getting new data, or finished loading feedback. So we flush manually.
      # Otherwise sometimes there were delays between change to subscriptionLimit and autoruns running.
      Tracker.flush() if oldSubscriptionLimit isnt @subscriptionLimit() or @distanceToScrollParentBottom() <= 0
    ,
      100 # ms

    @$scrollParent.on("scroll.peermind.#{@_eventHandlerId}", @handleScrolling)

    @autorun (computation) =>
      return unless @_subscriptionHandle.ready()

      # Every time the number of documents change, check if we should load even more.
      # This handles also loading all necessary documents to fill the scroll parent.
      @subscriptionDocument.documents.find(@_subscriptionHandle.scopeQuery()).count()

      # We want to wait for documents to render.
      Tracker.afterFlush =>
        # We cannot call it directly from inside the autorun because inside handleScrolling we call Tracker.flush.
        Meteor.defer @handleScrolling

  onDestroyed: ->
    super

    @$scrollParent?.off("scroll.peermind.#{@_eventHandlerId}")

  _distanceToScrollParentBottom: ->
    $listWrapper = @$('.list-wrapper')

    # If list is not visible, we cannot compute current height to know how much more we should load.
    return {} unless $listWrapper.is(':visible')

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

    {distanceToScrollParentBottom, scrollParentHeight}

  insertDOMElement: (parent, node, before, next) ->
    next ?= =>
      super parent, node, before
      true

    $node = $(node)
    if $node.hasClass 'finished-loading'
      next()

      if @slideInsteadFade
        $node.velocity 'slideDown',
          duration: 'slow'
          queue: false
          progress: (elements, complete, remaining, start) =>
            {distanceToScrollParentBottom} = @_distanceToScrollParentBottom()

            # If we are scrolled to the end, then make the end scrolling location
            # sticky and scroll as we are expanding the finished loading feedback.
            return unless distanceToScrollParentBottom? and distanceToScrollParentBottom <= 0

            @$scrollParent.scrollTop @$scrollParent.prop('scrollHeight') - @$scrollParent.height()

            return

      else
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
      $node.velocity('stop')

      if @slideInsteadFade
        $node.velocity 'slideUp',
          duration: 'slow'
          queue: false
          complete: (element) =>
            next()
      else
        $node.velocity 'fadeOut',
          duration: 'slow'
          queue: false
          complete: (element) =>
            next()

    else
      next()

    # We are handling it.
    true
