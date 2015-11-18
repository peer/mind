Meteor.startup ->
  # TODO: Create sub-roles for each action: "vote", "comment", "upvote".
  Roles.createRole 'admin', true
  Roles.createRole 'moderator', true
  Roles.createRole 'manager', true
  Roles.createRole 'member', true
