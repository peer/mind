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

      throw new Meteor.Error 'invalid-request', "Invalid username generated: '#{username}'" unless username and new RegExp("^#{Settings.USERNAME_REGEX}$").test username

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

Meteor.methods
  'User.profileUpdate': (profile) ->
    check profile, String

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    profile = Comment.sanitize.sanitizeHTML profile

    if profile
      if Meteor.isServer
        $root = cheerio.load(profile).root()
      else
        $root = $('<div/>').append($.parseHTML(profile))

      profileText = $root.text()

      # If content is empty, we set the profile to an empty string (instead of HTML tags without any content).
      # This helps us that we can display a message to a visitor that a profile is empty.
      profile = '' unless profileText or $root.has('figure').length

    attachments = User.extractAttachments profile
    mentions = User.extractMentions profile

    updatedAt = new Date()
    changed = User.documents.update
      _id: user._id
      profile:
        $ne: profile
    ,
      $set:
        updatedAt: updatedAt
        profile: profile
        profileAttachments: ({_id} for _id in attachments)
        profileMentions: ({_id} for _id in mentions)
      $push:
        changes:
          updatedAt: updatedAt
          author: user.getReference()
          profile: profile

    if changed
      StorageFile.documents.update
        _id:
          $in: attachments
      ,
        $set:
          active: true
      ,
        multi: true

    changed
