class Migration extends Document.ModifyGeneratedFieldsMigration
  name: "Changed avatars field generation to include PNG default avatar"
  fields: ['avatars']

User.addMigration new Migration()
