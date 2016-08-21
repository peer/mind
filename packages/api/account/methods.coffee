Meteor.methods
  'Settings.changeUsername': (newUsername) ->
    check newUsername, Match.Where (x) ->
      check x, String
      new RegExp("^#{Settings.USERNAME_REGEX}$").test x

    userId = Meteor.userId()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless userId

    Accounts.setUsername userId, newUsername
