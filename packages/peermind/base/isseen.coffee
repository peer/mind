isWindowFocused = new ReactiveField null

Meteor.startup ->
  focusChange = (event) ->
    return if isWindowFocused() is document.hasFocus()
    isWindowFocused document.hasFocus()

  debouncedFocusChange = _.debounce focusChange, 50 # ms

  $window = $(window)
  $document = $(document)

  $window.on('focus', debouncedFocusChange)
  $window.on('blur', debouncedFocusChange)

  $document.on('focus', debouncedFocusChange)
  $document.on('blur', debouncedFocusChange)

  # Initial value.
  focusChange()

EDGE_THRESHOLD = 0.05

# isVisible method has to be defined on the component for this mixin.
class share.IsSeenMixin extends UIMixin
  onCreated: ->
    super

    @isSeen = new ReactiveField null

  onRendered: ->
    super

    @_eventHandlerId = Random.id()

    firstNode = @firstNode()
    lastNode = @lastNode()

    node = firstNode
    while node
      if node.nodeType is Node.ELEMENT_NODE
        @$scrollParent = $(node).scrollParent()
        break

      break if node is lastNode

      node = node.nextSibling

    unless @$scrollParent
      console.error "Unable to find scroll parent."
      return

    $window = $(window)
    @$scrollParent = $window if @$scrollParent.get(0) is document

    @windowWidth = new ReactiveField $window.width()
    @windowHeight = new ReactiveField $window.height()
    @windowScrollLeft = new ReactiveField $window.scrollLeft()
    @windowScrollTop = new ReactiveField $window.scrollTop()

    @scrollLeft = new ReactiveField @$scrollParent.scrollLeft()
    @scrollTop = new ReactiveField @$scrollParent.scrollTop()

    $window.on("resize.peermind.#{@_eventHandlerId}", _.debounce (event) =>
      @windowWidth $window.width()
      @windowHeight $window.height()
    ,
      50 # ms
    )

    $window.on("scroll.peermind.#{@_eventHandlerId}", _.debounce (event) =>
      @windowScrollLeft $window.scrollLeft()
      @windowScrollTop $window.scrollTop()
    ,
      50 # ms
    )

    if @$scrollParent.get(0) isnt window
      @$scrollParent.on("scroll.peermind.#{@_eventHandlerId}", _.debounce (event) =>
        @scrollLeft @$scrollParent.scrollLeft()
        @scrollTop @$scrollParent.scrollTop()
      ,
        50 # ms
      )

    @autorun (computation) =>
      unless @isRendered() and isWindowFocused() and @callFirstWith null, 'isVisible'
        @isSeen false
        return

      left = null
      right = null
      top = null
      bottom = null

      # Register dependencies on scrolling and window size.
      @windowWidth()
      @windowHeight()
      @windowScrollLeft()
      @windowScrollTop()
      @scrollLeft()
      @scrollTop()

      firstNode = @firstNode()
      lastNode = @lastNode()

      node = firstNode
      while node
        if node.nodeType is Node.ELEMENT_NODE
          clientRect = node.getBoundingClientRect()

          left = clientRect.left if left is null or clientRect.left < left
          right = clientRect.right if right is null or clientRect.right > right
          top = clientRect.top if top is null or clientRect.top < top
          bottom = clientRect.bottom if bottom is null or clientRect.bottom > bottom

        break if node is lastNode

        node = node.nextSibling

      # Component is not visible.
      return if left is right or top is bottom

      scrollParent = @$scrollParent.get(0)
      if scrollParent is window
        scrollParentLeft = @windowScrollLeft()
        scrollParentTop = @windowScrollTop()
        scrollParentRight = scrollParentLeft + @windowWidth()
        scrollParentBottom = scrollParentTop + @windowHeight()
      else
        clientRect = scrollParent.getBoundingClientRect()
        scrollParentLeft = Math.max(clientRect.left, 0) + @windowScrollLeft()
        scrollParentTop = Math.max(clientRect.top, 0) + @windowScrollTop()
        scrollParentRight = Math.min(clientRect.right, @windowWidth() - 1) + @windowScrollLeft()
        scrollParentBottom = Math.min(clientRect.bottom, @windowHeight() - 1) + @windowScrollTop()

      # Converting coordinates to document-based.
      left += @windowScrollLeft()
      right += @windowScrollLeft()
      top += @windowScrollTop()
      bottom += @windowScrollTop()

      horizontalEdge = (scrollParentRight - scrollParentLeft) * EDGE_THRESHOLD
      verticalEdge = (scrollParentBottom - scrollParentTop) * EDGE_THRESHOLD

      @isSeen bottom >= scrollParentTop + verticalEdge and right >= scrollParentLeft + horizontalEdge and top < scrollParentBottom - verticalEdge and left < scrollParentRight - horizontalEdge

  onDestroyed: ->
    $window = $(window)

    $window.off("resize.peermind.#{@_eventHandlerId}")
    $window.off("scroll.peermind.#{@_eventHandlerId}")

    # @$scrollParent might be window but we do not care.
    @$scrollParent.off("scroll.peermind.#{@_eventHandlerId}")
