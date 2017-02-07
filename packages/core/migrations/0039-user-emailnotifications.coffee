class Migration extends Document.AddRequiredFieldsMigration
  name: "Adding emailNotifications field"
  fields:
    emailNotifications:
      userImmediately: true
      generalImmediately: true
      user4hours: false
      general4hours: false
      userDaily: false
      generalDaily: false
      userWeekly: false
      generalWeekly: false

User.addMigration new Migration()
