class HeaderComponent extends UIComponent
  @register 'HeaderComponent'

  onCreated: ->
    super

    # TODO: Use $medium-screen-up here. Check that it is "screen" as well?
    @largeScreen = new ReactiveField $(window).width() >= 993

  onRendered: ->
    super

    @$('.button-collapse').sideNav
      closeOnClick: true

    @_eventHandlerId = Random.id()

    # If side out menu is opened and window gets resized so that the responsive
    # design switches to large design, close the side out menu.
    $(window).on "resize.peermind.#{@_eventHandlerId}", (event) =>
      # TODO: Use $medium-screen-up here. Check that it is "screen" as well?
      @largeScreen $(window).width() >= 993

    @autorun (computation) =>
      @$('.button-collapse').sideNav('hide') if @largeScreen()

  onDestroyed: ->
    super

    # We have to remove the drag-target element added by sideNav
    # otherwise they are piling up every time header is rendered.
    $('body > .drag-target').remove()

    $(window).off "resize.peermind.#{@_eventHandlerId}"

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

class NotificationsComponent extends UIComponent
  @register 'NotificationsComponent'

  onCreated: ->
    super

    @componentId = Random.id()

    @countHandle = @subscribe 'Activity.unseenPersonalizedCount'

    @windowWidth = new ReactiveField $(window).width()
    @windowHeight = new ReactiveField $(window).height()

    @dropdownVisible = new ReactiveField false

    @notificationsSeeAllHeight = new ComputedField =>
      # Recompute height when dropdown visibility changes. .notifications-see-all's
      # height is not available when dropdown is not visible.
      return 0 unless @dropdownVisible()

      @$('.notifications-see-all').height() or 0

    @count = new ComputedField =>
      return 0 unless @countHandle.ready()

      @countHandle.data('count') or 0

  onRendered: ->
    super

    @$('.notifications-wrapper').scrollLock()

    # We use the fact that when it is rendered, we can enable dropdown inside the HeaderComponent
    # on dropdown's activator. This makes sure that dropdown is enabled even if it is not initially
    # rendered because an user is not yet signed in.
    @autorun (computation) =>
      $notificationsMenuActivator = @$('[data-activates="notifications-menu-' + @componentId + '"]')
      return unless $notificationsMenuActivator
      computation.stop()

      $notificationsMenuActivator.dropdown
        inDuration: 150
        outDuration: 150
        belowOrigin: true
        alignment: 'right'
        constrain_width: false

    @_eventHandlerId = Random.id()

    $(window).on "resize.peermind.#{@_eventHandlerId}", (event) =>
      @windowWidth $(window).width()
      @windowHeight $(window).height()

    # When dropdown is visible on a small screen (one tab) we cover with notifications the whole
    # screen. Because of that we want dropdown to behave like a modal, so we disable scrolling on body.
    @autorun (computation) =>
      $body = $('body')

      # TODO: Use $small-screen here.
      if @windowWidth() <= 600 and @dropdownVisible()
        $body.css
          overflow: 'hidden'
          width: $body.innerWidth()
      else
        # To not interfere with potentially opened sidenav overlay.
        # This can happen if user switches to sidenav directly from notifications.
        unless $('#sidenav-overlay').length
          $body.css
            overflow: ''
            width: ''

  onDestroyed: ->
    super

    $(window).off "resize.peermind.#{@_eventHandlerId}"

    # To not interfere with potentially opened sidenav overlay.
    # This can happen if user switches to sidenav directly from notifications.
    unless $('#sidenav-overlay').length
      $('body').css
        overflow: ''
        width: ''

  events: ->
    super.concat
      'dropdown:open': (event) ->
        @dropdownVisible true

        for component in @childComponents(Activity.ListContentComponent)
          component.handleScrolling?()

      'dropdown:close': (event) ->
        # We remove top and level CSS which were added by dropdown code so that the hidden content is moved back
        # to left. This is needed because if window is resized with hidden content being more to the right, then
        # the content gets squeezed once it hits the right window edge when resizing and then next time the
        # dropdown is displayed it does not have  the correct position, because its width was not correctly measured.
        # This is a similar reason to why we have left set to 0 on .dropdown-content to begin with.
        @$('.notifications-menu-item .dropdown-content').css
          top: ''
          left: ''

        @dropdownVisible false

  height: ->
    $notificationsMenuActivator = @$('[data-activates="notifications-menu-' + @componentId + '"]')
    $seeAll = @$('.notifications-see-all')

    # During initial run the element might not exist yet.
    return unless $notificationsMenuActivator and $seeAll

    offsetTop = $notificationsMenuActivator.offset().top - $(window).scrollTop() + $notificationsMenuActivator.height()

    # TODO: Use $small-screen here.
    if @windowWidth() <= 600
      # On small screens (one tab) we cover with notifications the whole screen.
      maxHeight: @windowHeight() - offsetTop - @notificationsSeeAllHeight()
    else
      # Leave some space at the bottom of the window.
      maxHeight: @windowHeight() - offsetTop - @notificationsSeeAllHeight() - 75

  # TODO: It should not be needed after: https://github.com/meteor/blaze/issues/5
  query: ->
    personalized: true