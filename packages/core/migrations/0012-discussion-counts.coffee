# In fact they are some reverse fields, not all generated fields.
class Migration extends Document.AddGeneratedFieldsMigration
  name: "Adding counts fields"
  fields: ['motions', 'comments', 'points', 'motionsCount', 'commentsCount', 'pointsCount']

Discussion.addMigration new Migration()
