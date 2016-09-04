class Migration extends Document.RemoveFieldsMigration
  name: "Removing inFavor and against fields"
  fields:
    inFavor: null
    against: null

Tally.addMigration new Migration()
