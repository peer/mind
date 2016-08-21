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

class Settings.UsernameComponent extends UIComponent
  @register 'Settings.UsernameComponent'

  onRendered: ->
    super

    Materialize.updateTextFields()

  events: ->
    super.concat
      'submit .change-username': @onSubmit

  onSubmit: (event) ->
    event.preventDefault()

    Meteor.call 'Settings.changeUsername', @$('[name="username"]').val(), (error, documentId) =>
      if error
        console.error "Change username error", error
        alert "Change username error: #{error.reason or error}"
        return

      event.target.reset()

  USERNAME_REGEX: ->
    Settings.USERNAME_REGEX

FlowRouter.route '/account/settings',
  name: 'Settings.display'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Settings.DisplayComponent'

    share.PageTitle "Settings"
