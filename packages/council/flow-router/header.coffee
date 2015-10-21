class HeaderComponent extends UIComponent
  @register 'HeaderComponent'

  onRendered: ->
    super

    @$('.button-collapse').sideNav()

  onDestroyed: ->
    # We have to remove the drag-target element added by sideNav
    # otherwise they are piling up every time header is rendered.
    $('body > .drag-target').remove()
