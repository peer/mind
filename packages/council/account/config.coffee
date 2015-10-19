Accounts.ui.config
  passwordSignupFields: 'USERNAME_AND_EMAIL'

AccountsTemplates.configure
  defaultTemplate: 'AccountFormComponent'
  defaultLayout: 'MainLayoutComponent'
  defaultLayoutRegions: {}
  defaultContentRegion: 'main'

AccountsTemplates.configureRoute 'signIn',
  name: 'Account.signIn',
  path: '/account/signin',
  #template: 'myLogin',
  #layoutTemplate: 'myLayout',
  #layoutRegions: {
  #  nav: 'myNav',
  #  footer: 'myFooter'
  #},
  #contentRegion: 'main'
