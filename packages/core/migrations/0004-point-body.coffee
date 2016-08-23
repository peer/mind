htmlToText = (html) ->
  html = html or ''

  $root = cheerio.load(html).root()

  $root.text()

textToHtml = (text) ->
  text = text or ''

  # A simple heuristic to not double convert by accident.
  return text if /^<[^>]+>.*<[^>]+>$/.test text.trim()

  "<div>#{text}</div>"

class Migration extends Document.MajorMigration
  name: "Converting body field to HTML"

  forward: (document, collection, currentSchema, newSchema) =>
    count = 0

    collection.findEach {_schema: currentSchema, body: {$exists: true}}, {_schema: 1, body: 1, changes: 1}, (document) =>
      count += collection.update document,
        $set:
          body: textToHtml document.body
          changes: (_.extend {}, change, {body: textToHtml change.body} for change in document.changes or [])
          _schema: newSchema

    counts = super
    counts.migrated += count
    counts.all += count
    counts

  backward: (document, collection, currentSchema, oldSchema) =>
    count = 0

    collection.findEach {_schema: currentSchema, body: {$exists: true}}, {_schema: 1, body: 1, changes: 1}, (document) =>
      count += collection.update document,
        $set:
          body: htmlToText document.body
          changes: (_.extend {}, change, {body: htmlToText change.body} for change in document.changes or [])
          _schema: oldSchema

    counts = super
    counts.migrated += count
    counts.all += count
    counts

Point.addMigration new Migration()
