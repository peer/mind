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

  'Account.selectAvatar': (name, argument) ->
    check name, Match.NonEmptyString
    check argument, Match.OptionalOrNull Match.NonEmptyString

    userId = Meteor.userId()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless userId

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
      avatars: currentAvatars
    ,
      $set:
        avatars: avatars
