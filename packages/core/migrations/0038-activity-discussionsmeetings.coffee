class Migration extends Document.MinorMigration
  name: "Adding forUsers data to discussionCreated and meetingCreated activities"

  forward: (document, collection, currentSchema, newSchema) =>
    users = User.documents.find(
      roles:
        $exists: true
        $ne: []
      'emails.verified': true
    ,
      transform: null
      fields:
        _id: 1
    ).fetch()

    count = collection.update
      _schema: currentSchema
      forUsers:
        $exists: false
      type:
        $in: ['discussionCreated', 'meetingCreated']
    ,
      $set:
        _schema: newSchema
        forUsers: users
    ,
      multi: true

    counts = super
    counts.migrated += count
    counts.all += count
    counts

  backward: (document, collection, currentSchema, oldSchema) =>
    count = collection.update
      _schema: currentSchema
      type:
        $in: ['discussionCreated', 'meetingCreated']
    ,
      $set:
        _schema: oldSchema
      $unset:
        forUsers: ''
    ,
      multi: true

    counts = super
    counts.migrated += count
    counts.all += count
    counts

Activity.addMigration new Migration()
