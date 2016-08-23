class Migration extends Document.AddGeneratedFieldsMigration
  name: "Adding avatars field"
  fields: ['avatars']

User.addMigration new Migration()
