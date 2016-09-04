class Migration extends Document.AddReferenceFieldsMigration
  name: "Adding title, startAt, and endAt fields to discussions"

Meeting.addMigration new Migration()
