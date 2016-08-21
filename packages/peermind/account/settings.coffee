class Settings.DisplayComponent extends UIComponent
  @register 'Settings.DisplayComponent'

  onRendered: ->
    super

    @$('.scrollspy').scrollSpy
      scrollOffset: 100

    @$('.table-of-contents').pushpin
      top: @$('.table-of-contents').position().top

  hasAccess: ->
    !!@currentUserId()

FlowRouter.route '/account/settings',
  name: 'Settings.display'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Settings.DisplayComponent'

    share.PageTitle "Settings"
