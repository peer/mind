# TODO: Make it configurable.
Accounts.emailTemplates.from = 'clonm@bsc.coop'
Accounts.emailTemplates.siteName = 'PeerMind'

subject = (user) ->
  "[#{Accounts.emailTemplates.siteName}] An account has been created for you"

_.extend Accounts.emailTemplates.resetPassword,
  subject: subject

_.extend Accounts.emailTemplates.enrollAccount,
  subject: subject

_.extend Accounts.emailTemplates.verifyEmail,
  subject: subject