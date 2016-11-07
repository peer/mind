class Migration extends Document.AddReferenceFieldsMigration
  name: "Adding activity data reference to activity"

Activity.addMigration new Migration()
