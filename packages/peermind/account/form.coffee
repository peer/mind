class AccountFormComponent extends UIComponent
  @register 'AccountFormComponent'

  isSignIn: ->
    AccountsTemplates.getState() is 'signIn'