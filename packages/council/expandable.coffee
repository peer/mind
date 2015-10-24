class share.ExpandableMixin extends UIMixin
  onCreated: ->
    super

    @_itemExpanded = new ReactiveField false
    @_itemExpandedSet = false

  events: ->
    super.concat
      'click .expand-button': @onExpandButton

  itemExpanded: (value) ->
    if arguments.length > 0
      @_itemExpanded value

      # To be able to know if DOM node is being removed because of itemExpanded change or
      # because of some other reason (like whole component being removed), we set a flag.
      @_itemExpandedSet = true
      Tracker.afterFlush =>
        @_itemExpandedSet = false

      return Tracker.nonreactive =>
        @_itemExpanded()

    @_itemExpanded()

  onExpandButton: (event) ->
    event.preventDefault()

    @itemExpanded not @itemExpanded()

  insertDOMElement: (parent, node, before, next) ->
    next ?= =>
      super parent, node, before
      true

    $node = $(node)
    if $node.hasClass('expansion') and @_itemExpandedSet
      next() unless @callFirstWith @, 'insertDOMElement', parent, node, before, next
      $node.velocity 'slideDown',
        duration: 'fast'
        queue: false

    else
      next() unless @callFirstWith @, 'insertDOMElement', parent, node, before, next

    # We are handling it.
    true

  removeDOMElement: (parent, node, next) ->
    next ?= =>
      super parent, node
      true

    $node = $(node)
    if $node.hasClass('expansion') and @_itemExpandedSet
      $node.velocity 'slideUp',
        duration: 'fast'
        queue: false
        complete: (element) =>
          next() unless @callFirstWith @, 'removeDOMElement', parent, node, next

    else
      next() unless @callFirstWith @, 'removeDOMElement', parent, node, next

    # We are handling it.
    true
