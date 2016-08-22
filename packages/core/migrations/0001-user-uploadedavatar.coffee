class Migration extends Document.AddOptionalFieldsMigration
  name: "Adding uploadedAvatar field"
  fields: ['uploadedAvatar']

User.addMigration new Migration()
