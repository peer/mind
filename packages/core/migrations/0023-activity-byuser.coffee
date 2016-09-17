class Migration extends Document.RenameFieldsMigration
  name: "Renaming user field to byUser in activity"
  fields:
    user: 'byUser'

Activity.addMigration new Migration()
