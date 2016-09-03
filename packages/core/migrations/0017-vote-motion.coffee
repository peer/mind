class Migration extends Document.AddReferenceFieldsMigration
  name: "Removing discussion.status subfield in motion field"

Vote.addMigration new Migration()
