class Migration extends Document.AddOptionalFieldsMigration
  name: "Adding changes field"
  fields: ['changes']

User.addMigration new Migration()
