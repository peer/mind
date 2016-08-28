# In fact it is a reverse field, not generated field.
class Migration extends Document.AddGeneratedFieldsMigration
  name: "Adding upvotesCount field"
  fields: ['upvotesCount']

Motion.addMigration new Migration()
