AccountsTemplates.configure
  confirmPassword: true
  enablePasswordChange: true
  forbidClientAccountCreation: true
  overrideLoginErrors: true
  sendVerificationEmail: false
  lowercaseUsername: false
  focusFirstInput: true
  showForgotPasswordLink: true

  defaultTemplate: 'AccountFormComponent'
  defaultLayout: 'MainLayoutComponent'
  defaultLayoutRegions: {}
  defaultContentRegion: 'main'

  #texts:
    # TODO: This adds extra space, see: https://github.com/meteor-useraccounts/core/issues/583
    #signInLink_suff: "."

AccountsTemplates.configureRoute 'signIn',
  name: 'Account.signIn'
  path: '/account/signin'

AccountsTemplates.configureRoute 'changePwd',
  name: 'Account.changePassword'
  path: '/account/password/change'

AccountsTemplates.configureRoute 'enrollAccount',
  name: 'Account.enrollAccount'
  path: '/account/enroll'

AccountsTemplates.configureRoute 'forgotPwd',
  name: 'Account.forgotPassword'
  path: '/account/password/forgot'

AccountsTemplates.configureRoute 'resetPwd',
  name: 'Account.resetPassword'
  path: '/account/password/reset'

passwordField = AccountsTemplates.removeField 'password'

AccountsTemplates.removeField 'email'

AccountsTemplates.addFields [
  _id: 'username'
  type: 'text'
  displayName: 'username'
  required: true
  minLength: 5
,
  _id: 'email'
  type: 'email'
  required: true
  displayName: 'email'
  # TODO: Better regex.
  re: /.+@(.+){2,}\.(.+){2,}/
  errStr: 'Invalid email'
,
  passwordField
]
