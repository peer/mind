class Migration extends Document.MajorMigration
  name: "Converting document fields in activity"

  fields: [
    ['upvote', 'data.document', ['Comment', 'Motion', 'Point']]
    ['removeUpvote', 'data.document', ['Comment', 'Motion', 'Point']]
    ['ui', 'data.data', ['Comment', 'Motion', 'Point', 'Meeting', 'Discussion']]
  ]

  forward: (document, collection, currentSchema, newSchema) =>
    count = 0

    for [type, fieldName, documentTypes] in @fields
      for documentType in documentTypes
        query =
          _schema: currentSchema
          type: type
        query["#{fieldName}._type"] = documentType

        update =
          $set:
            _schema: newSchema
          $rename: {}
        update.$rename[fieldName] = "data.#{documentType.toLowerCase()}"

        # We count only renaming fields.
        count += collection.update query, update, multi: true

        query =
          _schema: newSchema
          type: type
        query["data.#{documentType.toLowerCase()}._type"] =
          $exists: true

        update =
          $unset: {}
        update.$unset["data.#{documentType.toLowerCase()}._type"] = ''

        # This is just to cleanup obsolete _type field.
        collection.update query, update, multi: true

    counts = super
    counts.migrated += count
    counts.all += count
    counts

  backward: (document, collection, currentSchema, oldSchema) =>
    count = 0

    for [type, fieldName, documentTypes] in @fields
      for documentType in documentTypes
        query =
          _schema: currentSchema
          type: type
        query["data.#{documentType.toLowerCase()}._id"] =
          $exists: true

        update =
          $set: {}
        update.$set["data.#{documentType.toLowerCase()}._type"] = documentType

        # This is just to restore _type field.
        collection.update query, update, multi: true

        query =
          _schema: currentSchema
          type: type
        query["data.#{documentType.toLowerCase()}._type"] = documentType

        update =
          $set:
            _schema: oldSchema
          $rename: {}
        update.$rename["data.#{documentType.toLowerCase()}"] = fieldName

        # We count only renaming fields.
        count += collection.update query, update, multi: true

    counts = super
    counts.migrated += count
    counts.all += count
    counts

Activity.addMigration new Migration()
