class Migration extends Document.AddOptionalFieldsMigration
  name: "Adding lastSeenMeeting field"
  fields: ['lastSeenMeeting']

User.addMigration new Migration()
