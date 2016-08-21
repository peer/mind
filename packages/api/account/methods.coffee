Meteor.methods
  'Settings.changeUsername': (newUsername) ->
    check newUsername, Match.Where (x) ->
      check x, String
      new RegExp("^#{Settings.USERNAME_REGEX}$").test x

    userId = Meteor.userId()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless userId

    Accounts.setUsername userId, newUsername

  'Settings.unlinkAccount': (serviceName) ->
    check serviceName, Match.Where (x) ->
      check x, Match.NonEmptyString
      x in ['facebook']

    userId = Meteor.userId()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless userId

    unset = {}
    unset["services.#{serviceName}"] = ''

    User.documents.update
      _id: userId
    ,
      $unset: unset
