Meteor.methods
  # TODO: Temporary, to invite users.
  'User.invite': (email, username) ->
    check email, Match.NonEmptyString
    check username, Match.NonEmptyString

    # TODO: Temporary.
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless Roles.userIsInRole Meteor.userId(), ['admin']

    userId = Accounts.createUser
      email: email
      username: username

    Accounts.sendEnrollmentEmail userId

    userId
