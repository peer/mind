class Migration extends Document.AddReferenceFieldsMigration
  name: "Adding status to discussion"

Comment.addMigration new Migration()
Point.addMigration new Migration()
Motion.addMigration new Migration()
