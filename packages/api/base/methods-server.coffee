Meteor.methods
  # TODO: Temporary.
  'Admin.updateAll': ->
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless Meteor.userId()

    throw new Meteor.Error 'unauthorized', "Unauthorized." unless User.hasPermission User.PERMISSIONS.ACCOUNTS_ADMIN

    Document.updateAll()
