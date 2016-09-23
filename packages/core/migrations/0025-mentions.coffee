class BodyMigration extends Document.AddGeneratedFieldsMigration
  name: "Adding bodyMentions field"
  fields: ['bodyMentions']

class DiscussionMigration extends Document.AddGeneratedFieldsMigration
  name: "Adding descriptionMentions and closingNoteMentions fields"
  fields: ['descriptionMentions', 'closingNoteMentions']

class MeetingMigration extends Document.AddGeneratedFieldsMigration
  name: "Adding descriptionMentions field"
  fields: ['descriptionMentions']

class UserMigration extends Document.AddGeneratedFieldsMigration
  name: "Adding profileMentions field"
  fields: ['profileMentions']

Comment.addMigration new BodyMigration()
Motion.addMigration new BodyMigration()
Point.addMigration new BodyMigration()
Discussion.addMigration new DiscussionMigration()
Meeting.addMigration new MeetingMigration()
User.addMigration new UserMigration()
