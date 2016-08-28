class Migration extends Document.AddGeneratedFieldsMigration
  name: "Adding generated fields"
  fields: ['closingMotions', 'closingNote', 'closingNoteDisplay']

Discussion.addMigration new Migration()
