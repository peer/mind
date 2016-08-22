class MainLayoutComponent extends BlazeLayoutComponent
  @register 'MainLayoutComponent'

  @REGIONS:
    MAIN: 'main'

  renderMain: (parentComponent) ->
    @_renderRegion @constructor.REGIONS.MAIN, parentComponent

class ColumnsLayoutComponent extends BlazeLayoutComponent
  @register 'ColumnsLayoutComponent'

  @REGIONS:
    MAIN: 'main'
    FIRST: 'first'
    SECOND: 'second'
    THIRD: 'third'

  renderMain: (parentComponent) ->
    @_renderRegion @constructor.REGIONS.MAIN, parentComponent

  renderFirst: (parentComponent) ->
    @_renderRegion @constructor.REGIONS.FIRST, parentComponent

  renderSecond: (parentComponent) ->
    @_renderRegion @constructor.REGIONS.SECOND, parentComponent

  renderThird: (parentComponent) ->
    @_renderRegion @constructor.REGIONS.THIRD, parentComponent
