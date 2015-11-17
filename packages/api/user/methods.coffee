Meteor.methods
  # TODO: Temporary, to invite users.
  'User.invite': (email, username) ->
    check email, Match.NonEmptyString
    check username, Match.NonEmptyString

    userId = Accounts.createUser
      email: email
      username: username

    Accounts.sendEnrollmentEmail userId

    userId
