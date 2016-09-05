class MainLayoutComponent extends BlazeLayoutComponent
  @register 'MainLayoutComponent'

  @REGIONS:
    MAIN: 'main'

  renderMain: (parentComponent) ->
    @_renderRegion @constructor.REGIONS.MAIN, parentComponent

class ColumnsLayoutComponent extends BlazeLayoutComponent
  @register 'ColumnsLayoutComponent'

  # The rest of the code assumes there are four regions.
  @REGIONS:
    MAIN: 'main'
    FIRST: 'first'
    SECOND: 'second'
    THIRD: 'third'

  @REGIONS_ORDER = [
    @REGIONS.MAIN
    @REGIONS.FIRST
    @REGIONS.SECOND
    @REGIONS.THIRD
  ]

  onCreated: ->
    super

    # TODO: We should expose active tab(s) in the current URL as well.
    @activeTab = new ReactiveField @constructor.REGIONS.MAIN
    @previousActiveTab = new ReactiveField @constructor.REGIONS.FIRST

    @windowWidth = new ReactiveField $(window).width()

    @_eventHandlerId = Random.id()

    $(window).on "resize.columns-#{@_eventHandlerId}", (event) =>
      @windowWidth  $(window).width()

  onDestroyed: ->
    super

    $(window).off "resize.columns-#{@_eventHandlerId}"

  tabs: ->
    @constructor.REGIONS_ORDER

  activeClass: ->
    'active' if @visible @currentTab()

  # You will probably want to override this method.
  displayTab: ->
    regionName = @currentTab()

    return null unless regionName

    componentName = @_regionToComponentName regionName

    return regionName unless componentName

    if _.isString componentName
      component = BlazeComponent.getComponent componentName
    else
      # Otherwise we assume it is already a component.
      component = componentName

    return regionName unless component

    component?.displayTab?() or regionName

  onClick: (event) ->
    event.preventDefault()

    newIndex = _.indexOf @constructor.REGIONS_ORDER, @currentTab()
    currentlyActiveIndex = _.indexOf @constructor.REGIONS_ORDER, @activeTab()

    assert newIndex >= 0, newIndex
    assert currentlyActiveIndex >= 0, currentlyActiveIndex

    # If we are moving to the right.
    if newIndex > currentlyActiveIndex
      # We select the new tab and the tab on the left of it.
      @previousActiveTab @constructor.REGIONS_ORDER[newIndex - 1]
      @activeTab @constructor.REGIONS_ORDER[newIndex]
    # If we moving to the left.
    else if newIndex < currentlyActiveIndex
      # We select the new tab and the tab on the right of it.
      @previousActiveTab @constructor.REGIONS_ORDER[newIndex + 1]
      @activeTab @constructor.REGIONS_ORDER[newIndex]

    # If it is equal, then we do not do anything, a click was on the already active tab.

  visible: (name) ->
    # TODO: Use $medium-screen-up here. Check that it is "screen" as well?
    return true if @windowWidth() >= 993

    return true if @activeTab() is name

    # TODO: Use $small-screen-up here. Check that it is "screen" as well?
    return true if @windowWidth() >= 601 and @previousActiveTab() is name

    false

  currentTab: ->
    # To make sure it is a normal string. Because we use string directly as a data context it is unclear
    # if string is forced into a String object and then equality does not always work as expected.
    "#{@currentData()}"

  # ColumnsLayoutComponent is not inheriting from UIComponent so we cannot use "class" method.
  positionStyle: ->
    return unless @isRendered()

    # Register a dependency on the window width so that position is recomputed if window width changes.
    @windowWidth()

    return unless @visible @activeTab()

    currentlyActiveIndex = _.indexOf @constructor.REGIONS_ORDER, @activeTab()

    return unless currentlyActiveIndex >= 0

    $activeTab = @$('.tabs .tab').eq(currentlyActiveIndex)

    return unless $activeTab.length

    left = $activeTab.position().left
    right = $activeTab.offsetParent().width() - ($activeTab.position().left + $activeTab.width())

    if @visible @previousActiveTab()
      previousActiveIndex = _.indexOf @constructor.REGIONS_ORDER, @previousActiveTab()

      if previousActiveIndex >= 0
        $previousActiveTab = @$('.tabs .tab').eq(previousActiveIndex)

        if $previousActiveTab.length
         left = Math.min left, $previousActiveTab.position().left
         right = Math.min right, $previousActiveTab.offsetParent().width() - ($previousActiveTab.position().left + $previousActiveTab.width())

    style: "left: #{left}px; right: #{right}px"

  renderMain: (parentComponent) ->
    @_renderRegion @constructor.REGIONS.MAIN, parentComponent

  renderFirst: (parentComponent) ->
    @_renderRegion @constructor.REGIONS.FIRST, parentComponent

  renderSecond: (parentComponent) ->
    @_renderRegion @constructor.REGIONS.SECOND, parentComponent

  renderThird: (parentComponent) ->
    @_renderRegion @constructor.REGIONS.THIRD, parentComponent
