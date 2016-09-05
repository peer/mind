class ExpandableButton extends UIComponent
  @register 'ExpandableButton'

  onButtonClick: (event) ->
    event.preventDefault()

    # Toggle.
    @callAncestorWith 'expandWithAnimation', not @isExpanded()

  isExpanded: ->
    @callAncestorWith 'isExpanded'

class share.ExpandableMixin extends UIMixin
  onCreated: ->
    super

    @isExpanded = new ReactiveField false
    @_expandWithAnimation = false

  expandWithAnimation: (value) ->
    value = !!value

    @isExpanded value

    @_expandWithAnimation = true
    Tracker.afterFlush =>
      @_expandWithAnimation = false

    expandableEventData = @callFirstWith null, 'expandableEventData'

    return unless expandableEventData

    $(@firstNode()).trigger 'expandable.peermind', [value, expandableEventData]

  insertDOMElement: (parent, node, before, next) ->
    next ?= =>
      super parent, node, before
      true

    $node = $(node)
    if $node.hasClass('expansion') and @_expandWithAnimation
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
    if $node.hasClass('expansion') and @_expandWithAnimation
      # We can call just "stop" because it does not matter that we have not animated insertion
      # to the end and we have no "complete" callback on insertion as well to care about.
      $node.velocity('stop').velocity 'slideUp',
        duration: 'fast'
        queue: false
        complete: (element) =>
          next() unless @callFirstWith @, 'removeDOMElement', parent, node, next

    else
      next() unless @callFirstWith @, 'removeDOMElement', parent, node, next

    # We are handling it.
    true
