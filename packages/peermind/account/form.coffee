class AccountFormComponent extends UIComponent
  @register 'AccountFormComponent'

  isSignIn: ->
    AccountsTemplates.getState() is 'signIn'

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
