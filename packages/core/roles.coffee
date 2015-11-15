Meteor.startup ->
  Roles.createRole 'admin', true
  Roles.createRole 'moderator', true
  Roles.createRole 'voter', true
