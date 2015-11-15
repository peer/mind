Meteor.startup ->
  Roles.createRole 'admin', true
  Roles.createRole 'moderator', true
  # TODO: Create sub-roles for each action: "vote", "comment", "upvote".
  Roles.createRole 'member', true
