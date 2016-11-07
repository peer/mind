class Migration extends Document.AddOptionalFieldsMigration
  name: "Adding lastSeenPersonalizedActivity field"
  fields: ['lastSeenPersonalizedActivity']

User.addMigration new Migration()
