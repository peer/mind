class Migration extends Document.AddRequiredFieldsMigration
  name: "Adding upvotes field"
  fields:
    upvotes: []

Motion.addMigration new Migration()
