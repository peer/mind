Accounts.onCreateUser (options, user) ->
  # We simply ignore options.profile because we do not use profile.
  # This is passed by Sandstorm, for example.

  # Default settings for e-mail notifications.
  _.extend user,
    emailNotifications:
      userImmediately: true
      generalImmediately: true
      user4hours: false
      general4hours: false
      userDaily: false
      generalDaily: false
      userWeekly: false
      generalWeekly: false

  user
