class Migration extends Document.AddOptionalFieldsMigration
  name: "Adding forUsers field"
  fields: ['forUsers']

Activity.addMigration new Migration()
