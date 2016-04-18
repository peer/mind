Accounts.onCreateUser (options, user) ->
  # We simply ignore options.profile because we do not use profile.

  user

Accounts.validateNewUser (user) ->
  if Meteor.settings?.public?.sandstorm
    # When Sandstorm is enabled, we require Sandstorm service.
    return !!user?.services?.sandstorm

  else
    return true

Accounts.validateLoginAttempt (attempt) ->
  # It is already not allowed, do not do anything extra.
  unless attempt.allowed
    return false

  if Meteor.settings?.public?.sandstorm
    # When Sandstorm is enabled, we allow only Sandstorm login.
    return attempt.type is 'sandstorm'

  else
    return true
