# TODO: These methods should probably be renamed to User.* methods.

Meteor.methods
  'Account.changeName': (newName) ->
    check newName, String

    userId = Meteor.userId()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless userId

    User.documents.update
      _id: userId
    ,
      $set:
        name: newName.trim()
        nameSet: true

  'Account.researchData': (consent) ->
    check consent, Boolean

    userId = Meteor.userId()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless userId

    User.documents.update
      _id: userId
    ,
      $set:
        researchData: consent
