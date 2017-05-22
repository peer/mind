unless __meteor_runtime_config__.SANDSTORM
  Meteor.methods
    # TODO: Temporary, to invite users.
    'User.invite': (email, name) ->
      check email, Match.NonEmptyString
      check name, String

      email = email.toLowerCase()
      name = name.trim()

      throw new Meteor.Error 'unauthorized', "Unauthorized." unless Meteor.userId()

      throw new Meteor.Error 'unauthorized', "Unauthorized." unless User.hasPermission User.PERMISSIONS.ACCOUNTS_ADMIN

      user = Accounts.findUserByEmail email

      # Invite only if e-mail is not already verified (invitation has already been accepted).
      for userEmail in (user?.emails or []) when (userEmail?.address or '').toLowerCase() is email and userEmail?.verified
        return

      # Inverse of Settings.USERNAME_REGEX.
      username = email.split('@')[0]?.replace /^[^A-Za-z]+|[^A-Za-z0-9]+$|[^A-Za-z0-9_]+/g, ''

      unless username and _.isString username
        username = Random.id()

      while username.length < 4
        username = username + '1'

      throw new Meteor.Error 'invalid-request', "Invalid username generated: '#{username}'" unless new RegExp("^#{Settings.USERNAME_REGEX}$").test username

      if user
        userId = user._id
      else
        userId = Accounts.createUser
          email: email
          username: username

        if name
          User.documents.update
            _id: userId
          ,
            $set:
              name: name

      Accounts.sendEnrollmentEmail userId

      userId
