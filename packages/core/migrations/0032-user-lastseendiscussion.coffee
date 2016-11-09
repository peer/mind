class Migration extends Document.AddOptionalFieldsMigration
  name: "Adding lastSeenDiscussion field"
  fields: ['lastSeenDiscussion']

User.addMigration new Migration()
