Meteor.methods
  'Account.changeUsername': (newUsername) ->
    check newUsername, Match.Where (x) ->
      check x, String
      new RegExp("^#{Settings.USERNAME_REGEX}$").test x

    userId = Meteor.userId()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless userId

    Accounts.setUsername userId, newUsername

  'Account.unlinkAccount': (serviceName) ->
    check serviceName, Match.Where (x) ->
      check x, Match.NonEmptyString
      x in ['facebook', 'google', 'twitter']

    userId = Meteor.userId()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless userId

    unset = {}
    unset["services.#{serviceName}"] = ''

    User.documents.update
      _id: userId
    ,
      $unset: unset

unless __meteor_runtime_config__.SANDSTORM
  Meteor.methods
    'Account.selectAvatar': (name, argument) ->
      check name, Match.NonEmptyString
      check argument, Match.OptionalOrNull Match.NonEmptyString

      userId = Meteor.userId()
      throw new Meteor.Error 'unauthorized', "Unauthorized." unless userId

      # We fetch whole array and modify it here and set it back because it seems
      # there is no better way to do this directly through Mongo queries.
      currentAvatars = User.documents.findOne(userId, fields: avatars: 1)?.avatars

      return 0 unless currentAvatars

      avatars = EJSON.clone currentAvatars

      for avatar, i in avatars
        avatar.selected = false

      found = false
      for avatar in avatars when avatar.name is name and (avatar.argument or null) is (argument or null)
        avatar.selected = true
        found = true
        break

      return 0 unless found

      User.documents.update
        _id: userId
        # We make sure nothing changed in meantime. If so, update does not change
        # anything and user will have to re-select an avatar they want.
        avatars: currentAvatars
      ,
        $set:
          avatars: avatars
