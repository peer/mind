Accounts.onCreateUser (options, user) ->
  # We simply ignore options.profile because we do not use profile.
  # This is passed by Sandstorm, for example.

  user
