class Migration extends Document.ModifyGeneratedFieldsMigration
  name: "Changed avatar field generation"
  fields: ['avatar']

User.addMigration new Migration()
