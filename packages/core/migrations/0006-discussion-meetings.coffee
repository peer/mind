# In fact it is a reverse field, not generated field.
class Migration extends Document.AddGeneratedFieldsMigration
  name: "Adding meetings field"
  fields: ['meetings']

Discussion.addMigration new Migration()
