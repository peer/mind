class Migration extends Document.AddOptionalFieldsMigration
  name: "Adding discussionFollowing field"
  fields: ['discussionFollowing']

User.addMigration new Migration()
