Meteor.startup ->
  Roles.createRole 'admin', true
  Roles.createRole 'moderator', true
  # TODO: Create sub-roles for each action: "voter", "commenter", "upvoter"
  Roles.createRole 'member', true
