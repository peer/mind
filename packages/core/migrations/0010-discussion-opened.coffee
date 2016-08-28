class Migration extends Document.MinorMigration
  name: "Adding opened fields"

  forward: (document, collection, currentSchema, newSchema) =>
    count = 0

    collection.findEach {_schema: currentSchema, discussionOpenedBy: {$exists: false}, discussionOpenedAt: {$exists: false}}, {_schema: 1, author: 1, createdAt: 1}, (document) =>
      count += collection.update document,
        $set:
          discussionOpenedBy: document.author
          discussionOpenedAt: document.createdAt
          _schema: newSchema

    counts = super
    counts.migrated += count
    counts.all += count
    counts

  backward: (document, collection, currentSchema, oldSchema) =>
    count = 0

    count = collection.update
      _schema: currentSchema
    ,
      $set:
        _schema: oldSchema
      $unset:
        discussionOpenedBy: ''
        discussionOpenedAt: ''
    ,
      multi: true

    counts = super
    counts.migrated += count
    counts.all += count
    counts

Discussion.addMigration new Migration()
