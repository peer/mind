$window = $(window)

windowWidth = new ReactiveField $window.width()
windowHeight = new ReactiveField $window.height()
scrollLeft = new ReactiveField $window.scrollLeft()
scrollTop = new ReactiveField $window.scrollTop()
isWindowFocused = new ReactiveField null

Meteor.startup ->
  focusChange = (event) ->
    return if isWindowFocused() is document.hasFocus()
    isWindowFocused document.hasFocus()

  debouncedFocusChange = _.debounce focusChange, 50 # ms

  $document = $(document)

  $document.on 'focus', debouncedFocusChange
  $document.on 'blur', debouncedFocusChange

  $window.on 'focus', debouncedFocusChange
  $window.on 'blur', debouncedFocusChange

  $window.on 'resize', _.debounce (event) ->
    windowWidth $window.width()
    windowHeight $window.height()
  ,
    50 # ms

  $window.on 'scroll', _.debounce (event) ->
    scrollLeft $window.scrollLeft()
    scrollTop $window.scrollTop()
  ,
    50 # ms

  # Initial value.
  focusChange()

EDGE_THRESHOLD = 0.1

class share.IsSeenMixin extends UIMixin
  onCreated: ->
    super

    @isSeen = new ReactiveField null

  onRendered: ->
    super

    @autorun (computation) =>
      unless @isRendered() and isWindowFocused()
        @isSeen false
        return

      left = null
      right = null
      top = null
      bottom = null

      # Register dependency on scrolling.
      scrollLeft()
      scrollTop()

      firstNode = @firstNode()
      lastNode = @lastNode()

      node = firstNode
      while node
        # Not all elements have getBoundingClientRect, like text elements.
        if node.getBoundingClientRect
          clientRect = node.getBoundingClientRect()

          left = clientRect.left if left is null or clientRect.left < left
          right = clientRect.right if right is null or clientRect.right > right
          top = clientRect.top if top is null or clientRect.top < top
          bottom = clientRect.bottom if bottom is null or clientRect.bottom > bottom

        break if node is lastNode

        node = node.nextSibling

      # Component is not visible.
      return if left is right or top is bottom

      horizontalEdge = windowWidth() * EDGE_THRESHOLD
      verticalEdge = windowHeight() * EDGE_THRESHOLD

      @isSeen bottom >= verticalEdge and right >= horizontalEdge and top < windowHeight() - verticalEdge and left < windowWidth() - horizontalEdge
