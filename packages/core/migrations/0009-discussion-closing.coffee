class Migration extends Document.AddRequiredFieldsMigration
  name: "Adding closing fields"
  fields:
    discussionClosedBy: null
    discussionClosedAt: null
    closingMotions: []
    closingNote: ''
    closingNoteDisplay: ''

Discussion.addMigration new Migration()
