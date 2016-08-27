class Settings.DisplayComponent extends UIComponent
  @register 'Settings.DisplayComponent'

  onCreated: ->
    super

    @subscribe 'User.settings'

  onRendered: ->
    super

    @autorun (computation) =>
      return unless @hasAccess() and Accounts._loginServicesHandle.ready() and @subscriptionsReady()
      computation.stop()

      Tracker.afterFlush =>
        # TODO: We should reinitialize scrollSpy when position of elements changes.
        #       We could simply have an autorun observing any change to @currentUser() and reinitializing (maybe with debounce).
        #       See: https://github.com/Dogfalo/materialize/issues/3557
        @$('.scrollspy').scrollSpy
          scrollOffset: 100

        @$('.table-of-contents').pushpin
          top: @$('.table-of-contents').position().top

  hasAccess: ->
    !!@currentUserId()

  anyServiceConfiguration: ->
    ServiceConfiguration.configurations.find().exists()

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

    Meteor.call 'Account.changeUsername', @$('[name="username"]').val(), (error) =>
      if error
        console.error "Change username error", error
        alert "Change username error: #{error.reason or error}"
        return

      event.target.reset()

  USERNAME_REGEX: ->
    Settings.USERNAME_REGEX

class Settings.PasswordComponent extends UIComponent
  @register 'Settings.PasswordComponent'

  onRendered: ->
    super

    Materialize.updateTextFields()

  events: ->
    super.concat
      'submit .change-password': @onSubmit

  onSubmit: (event) ->
    event.preventDefault()

    newPassword = @$('[name="new-password"]').val()
    confirmNewPassword = @$('[name="confirm-new-password"]').val()

    # Just to be sure. Form validation should catch this.
    unless newPassword is confirmNewPassword
      # TODO: Use flash messages.
      alert "Password do not match."
      return

    Accounts.changePassword @$('[name="old-password"]').val(), newPassword, (error) =>
      if error
        console.error "Change password error", error
        alert "Change password error: #{error.reason or error}"
        return

      event.target.reset()

  linkText: ->
    T9n.get AccountsTemplates.texts.pwdLink_link, markIfMissing: false

  onForgotPassword: (event) ->
    event.preventDefault()

    email = Meteor.user()?.emails[0].address
    unless email
      # TODO: Use flash messages.
      alert "E-mail address missing."
      return

    # TODO: We should probably first display a submit form button for confirmation.
    #       The same form as it is for the reset password form, just without the e-mail address input field.
    Accounts.forgotPassword email: email, (error) =>
      if error
        console.error "Forgot password error", error
        alert "Forgot password error: #{error.reason or error}"
        return

      alert "Reset password e-mail has been sent to '#{email}'."

class Settings.AccountsComponent extends UIComponent
  @register 'Settings.AccountsComponent'

  onLink: (event, serviceName) ->
    event.preventDefault()

    Meteor["loginWith#{_.capitalize serviceName}"]
      requestPermissions: Accounts.ui._options.requestPermissions[serviceName]
    ,
      (error) =>
        if error
          console.error "Linking with #{_.capitalize serviceName} error", error
          alert "Linking with #{_.capitalize serviceName} error: #{error.reason or error}"

  onUnlink: (event, serviceName) ->
    event.preventDefault()

    Meteor.call 'Account.unlinkAccount', serviceName, (error, result) =>
      if error
        console.error "Unlinking from #{_.capitalize serviceName} error", error
        alert "Unlinking from #{_.capitalize serviceName} error: #{error.reason or error}"

class Settings.AvatarComponent extends UIComponent
  @register 'Settings.AvatarComponent'

  onSelect: (event, name, argument) ->
    event.preventDefault()

    Meteor.call 'Account.selectAvatar', name, (argument or null), (error, result) =>
      if error
        console.error "Selecting avatar error", error
        alert "Selecting avatar error: #{error.reason or error}"
        return

class Settings.ResearchDataComponent extends UIComponent
  @register 'Settings.ResearchDataComponent'

  constructor: (kwargs) ->
    super

    @isSettings = !!kwargs?.hash?.isSettings

  checked: (value) ->
    return unless @isSettings

    if @currentUser()?.researchData
      return checked: true if value is 'yes'
    else if @currentUser()?.researchData?
      return checked: true if value is 'no'

  onChange: (event) ->
    return unless @isSettings

    event.preventDefault()

    consent = @$('[name="research-data"]:checked').val()

    return unless consent

    Meteor.call 'Account.researchData', consent is 'yes', (error) =>
      if error
        console.error "Setting research data error", error
        alert "Setting research data error: #{error.reason or error}"

        # TODO: This should set it to old value, which is not necessary that no radio button was selected.
        @$('[name="research-data"]').prop('checked', false)

FlowRouter.route '/account/settings',
  name: 'Settings.display'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Settings.DisplayComponent'

    share.PageTitle "Settings"
