class Migration extends Document.AddReferenceFieldsMigration
  name: "Adding data references to activity"

Activity.addMigration new Migration()
