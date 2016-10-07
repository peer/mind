class Migration extends Document.PatchMigration
  name: "Fixing type field in activity"

  # There was a bug where all upvoting related Activity documents had _type equal to "Point".
  # We assume here that IDs are unique across documents of different collections.
  forward: (document, collection, currentSchema, newSchema) =>
    count = 0

    collection.findEach {_schema: currentSchema, type: {$in: ['upvote', 'removeUpvote']}, 'data.document._type': 'Point'}, {_schema: 1, 'data.document': 1}, (document) =>
      for type in [Comment, Motion, Point]
        if type.documents.exists(_id: document.data.document._id)
          count += collection.update document,
            $set:
              'data.document._type': type.Meta._name
              _schema: newSchema

          return

      console.warn "Unknown 'data.document' reference '#{document.data.document._id}' in Activity document '#{document._id}'."

    counts = super
    counts.migrated += count
    counts.all += count
    counts

Activity.addMigration new Migration()
