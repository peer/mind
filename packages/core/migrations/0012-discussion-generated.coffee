# In fact they are some reverse fields, not all generated fields.
class Migration extends Document.AddGeneratedFieldsMigration
  name: "Adding generated fields"
  fields: ['closingMotions', 'closingNote', 'closingNoteDisplay', 'status', 'motions', 'comments', 'points', 'motionsCount', 'commentsCount', 'pointsCount']

Discussion.addMigration new Migration()
