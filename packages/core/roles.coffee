Meteor.startup ->
  # TODO: When we migrate to roles 2.0 package create all permissions and default roles over them.
  for roleKey of User.ROLES
    # All this is hard-coded for now. We convert to lower case.
    Roles.createRole roleKey.toLowerCase(), true
