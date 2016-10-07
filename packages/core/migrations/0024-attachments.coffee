class Migration extends Document.AddReferenceFieldsMigration
  name: "Defining attachments as reference fields"

Comment.addMigration new Migration()
Point.addMigration new Migration()
Motion.addMigration new Migration()
Discussion.addMigration new Migration()
Meeting.addMigration new Migration()
User.addMigration new Migration()
