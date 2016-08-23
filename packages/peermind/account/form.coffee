class AccountFormComponent extends UIComponent
  @register 'AccountFormComponent'

  isSignIn: ->
    AccountsTemplates.getState() is 'signIn'

  siteName: ->
    Accounts.emailTemplates.siteName

  from: ->
    Accounts.emailTemplates.from

class PasswordFieldsComponent extends UIComponent
  @register 'PasswordFieldsComponent'

  constructor: (kwargs) ->
    super

    @isChange = !!kwargs?.hash?.isChange

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

class EnrollFormComponent extends UIComponent
  @register 'EnrollFormComponent'

  onCreated: ->
    super

    @currentToken = new ComputedField =>
      FlowRouter.getParam 'token'

  onSubmit: (event) ->
    event.preventDefault()

    newPassword = @$('[name="new-password"]').val()
    confirmNewPassword = @$('[name="confirm-new-password"]').val()

    # Just to be sure. Form validation should catch this.
    unless newPassword is confirmNewPassword
      # TODO: Use flash messages.
      alert "Password do not match."
      return

    consent = @$('[name="research-data"]:checked').val()

    unless consent
      # TODO: We cannot use required for radio input with Materialize.
      #       See https://github.com/Dogfalo/materialize/issues/2187
      # TODO: Use flash messages.
      alert "Deciding on contributing research data is required."
      return

    Accounts.callLoginMethod
      methodName: 'resetPassword'
      methodArguments: [@currentToken(), Accounts._hashPassword(newPassword), consent is 'yes']
      userCallback: (error) =>
        if error
          console.error "Register error", error
          alert "Register error: #{error.reason or error}"
          return

        # TODO: Display a flash message that registration was successful.

        FlowRouter.go 'Settings.display'
        $(window).scrollTop(0)

# This route has to be defined on the server side as well so that
# Accounts.urls.enrollAccount can resolve the enroll URL.
FlowRouter.route '/account/enroll/:token',
  name: 'Account.enrollAccount'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'EnrollFormComponent'

    share.PageTitle "Create an Account"
