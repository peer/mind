Meteor.methods
  # TODO: Temporary, to invite users.
  'User.invite': (email, username) ->
    check email, Match.NonEmptyString
    check username, Match.NonEmptyString

    throw new Meteor.Error 'unauthorized', "Unauthorized." unless Meteor.userId()

    throw new Meteor.Error 'unauthorized', "Unauthorized." unless User.hasPermission User.PERMISSIONS.USER_ADMIN

    userId = Accounts.createUser
      email: email
      username: username

    Accounts.sendEnrollmentEmail userId

    userId
