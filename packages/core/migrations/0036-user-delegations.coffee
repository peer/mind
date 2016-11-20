class Migration extends Document.AddReferenceFieldsMigration
  name: "Adding delegations field"

User.addMigration new Migration()
