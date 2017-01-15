Accounts.emailTemplates ?= {}

# TODO: Make it configurable.
Accounts.emailTemplates.from = 'admin@peermind.org'
Accounts.emailTemplates.siteName = 'PeerMind'

Accounts.emailTemplates.resetPassword ?= {}
_.extend Accounts.emailTemplates.resetPassword,
  subject: (user) ->
    "[#{Accounts.emailTemplates.siteName}] How to reset your password"

Accounts.emailTemplates.enrollAccount ?= {}
_.extend Accounts.emailTemplates.enrollAccount,
  subject: (user) ->
    "[#{Accounts.emailTemplates.siteName}] An account has been created for you"

  text: (user, url) ->
    """
    Hi!

    An account for online council app has been created for you.
    You can set your password and sign in for the first time
    by clicking the link:

    #{url}

    If you have any issues signing in or if you have any feedback
    about the app, feel free to write back.


    Mitar
    """

Accounts.emailTemplates.verifyEmail ?= {}
_.extend Accounts.emailTemplates.verifyEmail,
  subject: (user) ->
    "[#{Accounts.emailTemplates.siteName}] How to verify e-mail address"
