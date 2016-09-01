class Migration extends Document.AddGeneratedFieldsMigration
  name: "Adding profile, profileDisplay and profileAttachments fields"
  fields: ['profile', 'profileDisplay', 'profileAttachments']

User.addMigration new Migration()
