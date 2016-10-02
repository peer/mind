class Migration extends Document.AddGeneratedFieldsMigration
  name: "Adding followersCount field"
  fields: ['followersCount']

Discussion.addMigration new Migration()
