class Migration extends Document.RemoveGeneratedFieldsMigration
  name: "Removing display fields"
  fields: ['bodyDisplay']

Comment.addMigration new Migration()
Point.addMigration new Migration()
Motion.addMigration new Migration()

class UserMigration extends Document.RemoveGeneratedFieldsMigration
  name: "Removing display fields"
  fields: ['profileDisplay']

User.addMigration new UserMigration()

class MeetingMigration extends Document.RemoveGeneratedFieldsMigration
  name: "Removing display fields"
  fields: ['descriptionDisplay']

Meeting.addMigration new MeetingMigration()

class DiscussionMigration extends Document.RemoveGeneratedFieldsMigration
  name: "Removing display fields"
  fields: ['descriptionDisplay', 'closingNoteDisplay']

Discussion.addMigration new DiscussionMigration()
