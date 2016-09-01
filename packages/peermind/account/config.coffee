# We do not use accounts-ui package, but we have to use its options to configure useraccounts package.
Accounts.ui ?= {}
Accounts.ui._options ?=
  requestPermissions: {}
  requestOfflineToken: {}
  forceApprovalPrompt: {}

Accounts.ui._options.requestPermissions.facebook = ['public_profile', 'email', 'user_friends']
Accounts.ui._options.requestPermissions.google = ['https://www.googleapis.com/auth/userinfo.email', 'https://www.googleapis.com/auth/contacts.readonly', 'https://www.googleapis.com/auth/plus.circles.members.read']
Accounts.ui._options.requestPermissions.twitter = null

Accounts.config
  passwordResetTokenExpirationInDays: 30

if __meteor_runtime_config__.SANDSTORM
  AccountsTemplates.configure
    forbidClientAccountCreation: true

else
  AccountsTemplates.configure
    confirmPassword: true
    enablePasswordChange: true
    forbidClientAccountCreation: true
    overrideLoginErrors: false
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
    minLength: 4
    re: new RegExp "^#{Settings.USERNAME_REGEX}$"
    errStr: "Username can contain only A-Z, a-z, 0-9, and _ characters"
  ,
    _id: 'email'
    type: 'email'
    required: true
    displayName: 'email'
    # TODO: Better regex.
    re: /.+@(.+){2,}\.(.+){2,}/
    errStr: "Invalid email"
  ,
    passwordField
  ]

  if Meteor.isServer
    Accounts.urls.enrollAccount = (token) ->
      path = FlowRouter.path 'Account.enrollAccount',
        token: token

      Meteor.absoluteUrl path.substr 1

if Meteor.isServer
  # We disable all service configurations from the client. We do not use this feature.
  # See: https://github.com/meteor/meteor/issues/7745
  MethodHooks.before 'configureLoginService', (options) ->
    throw new Meteor.Error 'invalid-request', "Disabled."