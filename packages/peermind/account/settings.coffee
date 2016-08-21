class Settings.DisplayComponent extends UIComponent
  @register 'Settings.DisplayComponent'

  onRendered: ->
    super

    @autorun (computation) =>
      return unless @hasAccess() and Accounts._loginServicesHandle.ready()
      computation.stop()

      Tracker.afterFlush =>
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

    Meteor.call 'Settings.changeUsername', @$('[name="username"]').val(), (error) =>
      if error
        console.error "Change username error", error
        alert "Change username error: #{error.reason or error}"
        return

      event.target.reset()

  USERNAME_REGEX: ->
    Settings.USERNAME_REGEX

class Settings.PasswordComponent extends UIComponent
  @register 'Settings.PasswordComponent'

  onCreated: ->
    super

    @newPasswordChanged = false
    @confirmNewPasswordChanged = false

  onRendered: ->
    super

    Materialize.updateTextFields()

  events: ->
    super.concat
      'change #new-password': @onNewPasswordChange
      'change #confirm-new-password': @onConfirmNewPasswordChange
      'input #new-password, input #confirm-new-password': @checkPasswordsMatch
      # For some reason change event is not send always, so we also change it on blur.
      'blur #new-password', @onNewPasswordChange
      'blur #confirm-new-password': @onConfirmNewPasswordChange
      'submit .change-password': @onSubmit

  onNewPasswordChange: (event) ->
    # Because we are calling this even on blur as well, we set it only if there is content.
    @newPasswordChanged = true if @$('[name="new-password"]').val()

    @checkPasswordsMatch event

  onConfirmNewPasswordChange: (event) ->
    # Because we are calling this even on blur as well, we set it only if there is content.
    @confirmNewPasswordChanged = true if @$('[name="confirm-new-password"]').val()

    @checkPasswordsMatch event

  checkPasswordsMatch: (event) ->
    $confirmNewPasswordInput = @$('[name="confirm-new-password"]')
    confirmNewPasswordInput = $confirmNewPasswordInput.get(0)

    unless @newPasswordChanged and @confirmNewPasswordChanged
      confirmNewPasswordInput.setCustomValidity ""
      validate_field $confirmNewPasswordInput
      return

    newPassword = @$('[name="new-password"]').val()
    confirmNewPassword = @$('[name="confirm-new-password"]').val()

    unless newPassword and confirmNewPassword
      @newPasswordChanged = false unless newPassword
      @confirmNewPasswordChanged = false unless confirmNewPassword

      confirmNewPasswordInput.setCustomValidity ""
      validate_field $confirmNewPasswordInput
      return

    if newPassword is confirmNewPassword
      confirmNewPasswordInput.setCustomValidity ""
      validate_field $confirmNewPasswordInput
      return

    confirmNewPasswordInput.setCustomValidity "Passwords do not match."
    validate_field $confirmNewPasswordInput

  onSubmit: (event) ->
    event.preventDefault()

    newPassword = @$('[name="new-password"]').val()
    confirmNewPassword = @$('[name="confirm-new-password"]').val()

    # Just to be sure. Form validation should catch this.
    # TODO: Make a warning or something?
    return unless newPassword is confirmNewPassword

    Accounts.changePassword @$('[name="old-password"]').val(), newPassword, (error) =>
      if error
        console.error "Change password error", error
        alert "Change password error: #{error.reason or error}"
        return

      event.target.reset()

class Settings.AccountsComponent extends UIComponent
  @register 'Settings.AccountsComponent'

  onFacebook: (event) ->
    event.preventDefault()

    Meteor.loginWithFacebook
      requestPermissions: ['user_friends', 'public_profile', 'email']
    ,
      (error) =>
        if error
          console.error "Linking with Facebook error", error
          alert "Linking with Facebook error: #{error.reason or error}"
          return

  onUnlinkFacebook: (event) ->
    event.preventDefault()

    Meteor.call 'Settings.unlinkAccount', 'facebook', (error, result) =>
      if error
        console.error "Unlinking from Facebook error", error
        alert "Unlinking from Facebook error: #{error.reason or error}"
        return

FlowRouter.route '/account/settings',
  name: 'Settings.display'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Settings.DisplayComponent'

    share.PageTitle "Settings"
