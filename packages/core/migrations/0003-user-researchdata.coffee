class Migration extends Document.AddOptionalFieldsMigration
  name: "Adding researchData field"
  fields: ['researchData']

User.addMigration new Migration()
