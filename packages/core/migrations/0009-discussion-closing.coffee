class Migration extends Document.AddRequiredFieldsMigration
  name: "Adding closing fields"
  fields:
    discussionClosedBy: null
    discussionClosedAt: null
    passingMotions: []
    closingNote: ''
    closingNoteDisplay: ''

Discussion.addMigration new Migration()
