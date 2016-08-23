class Migration extends Document.AddGeneratedFieldsMigration
  name: "Adding bodyDisplay and bodyAttachments fields"
  fields: ['bodyDisplay', 'bodyAttachments']

Point.addMigration new Migration()
