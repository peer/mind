unless __meteor_runtime_config__.SANDSTORM
  Meteor.methods
    # TODO: Temporary, to invite users.
    'User.invite': (email, username) ->
      check email, Match.NonEmptyString
      check username, Match.NonEmptyString

      throw new Meteor.Error 'unauthorized', "Unauthorized." unless Meteor.userId()

      throw new Meteor.Error 'unauthorized', "Unauthorized." unless User.hasPermission User.PERMISSIONS.ACCOUNTS_ADMIN

      userId = Accounts.createUser
        email: email
        username: username

      Accounts.sendEnrollmentEmail userId

      userId
