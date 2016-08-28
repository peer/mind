class Migration extends Document.AddGeneratedFieldsMigration
  name: "Adding status field"
  fields: ['status']

Motion.addMigration new Migration()
