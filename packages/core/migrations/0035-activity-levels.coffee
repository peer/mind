class Migration extends Document.PatchMigration
  name: "Use ERROR level for errors"

  forward: (document, collection, currentSchema, newSchema) =>
    selector =
      _schema: currentSchema
      type:
        $in: ['accountUnlinkFailure', 'researchDataFailure', 'usernameChangeFailure', 'passwordChangeFailure', 'avatarSelectionFailure']
      level:
        $ne: Activity.LEVEL.ERROR

    update =
      $set:
        _schema: newSchema
        level: Activity.LEVEL.ERROR

    count = collection.update selector, update, {multi: true}

    counts = super
    counts.migrated += count
    counts.all += count
    counts

  backward: (document, collection, currentSchema, oldSchema) =>
    selector =
      _schema: currentSchema
      type:
        $in: ['accountUnlinkFailure', 'usernameChangeFailure', 'passwordChangeFailure', 'avatarSelectionFailure']
      level: Activity.LEVEL.ERROR

    update =
      $set:
        _schema: oldSchema
        level: Activity.LEVEL.ADMIN

    count = collection.update selector, update, {multi: true}

    selector =
      _schema: currentSchema
      type: 'researchDataFailure'
      level: Activity.LEVEL.ERROR

    update =
      $set:
        _schema: oldSchema
        level: Activity.LEVEL.DEBUG

    count += collection.update selector, update, {multi: true}

    counts = super
    counts.migrated += count
    counts.all += count
    counts

Activity.addMigration new Migration()
