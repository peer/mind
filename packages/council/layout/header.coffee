class HeaderComponent extends UIComponent
  @register 'HeaderComponent'

  onRendered: ->
    super

    @$('.button-collapse').sideNav
      closeOnClick: true

    @_eventHandlerId = Random.id()

    # If side out menu is opened and window gets resized so that the responsive
    # design switches to large design, close the side out menu.
    $(window).on "resize.sideNav-#{@_eventHandlerId}", (event) =>
      # TODO: Use $medium-screen-up here. Check that is is "screen" as well?
      @$('.button-collapse').sideNav('hide') if $(window).width() >= 993

  onDestroyed: ->
    super

    # We have to remove the drag-target element added by sideNav
    # otherwise they are piling up every time header is rendered.
    $('body > .drag-target').remove()

    $(window).off "resize.sideNav-#{@_eventHandlerId}"

  events: ->
    super.concat
      # Just to be sure.
      'click .account': (event) -> event.preventDefault()
      'click .sign-out': @onSignOut

  onSignOut: (event) ->
    event.preventDefault()

    AccountsTemplates.logout()

  title: ->
    share.PageTitle()

class AccountItemsComponent extends UIComponent
  @register 'AccountItemsComponent'

  constructor: (kwargs) ->
    super

    _.extend @, _.pick (kwargs?.hash or {}), 'isDropdown'

  onRendered: ->
    super

    return unless @isDropdown

    # If this component is used in a dropdown, then we use the fact that when it is rendered, we
    # can enable dropdown inside the HeaderComponent on dropdown's activator. This makes sure that
    # dropdown is enabled even if it is not initially rendered because an user is not yet signed in.
    @autorun (computation) =>
      $accountMenuActivator = @ancestorComponent(HeaderComponent).$('[data-activates="account-menu"]')
      return unless $accountMenuActivator
      computation.stop()

      $accountMenuActivator.dropdown
        inDuration: 150
        outDuration: 150
        belowOrigin: true
        alignment: 'right'
        constrain_width: false
