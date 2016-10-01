addFollower = (followers, user, reason) ->
  assert user

  for follower in followers when follower.user._id is user._id
    # Just return if user is already among followers.
    return followers

  followers.push
    user:
      _id: user._id
    reason: reason

  followers

class Migration extends Document.MajorMigration
  name: "Adding followers field"

  forward: (document, collection, currentSchema, newSchema) =>
    count = 0

    collection.findEach {_schema: currentSchema, followers: {$exists: false}}, {_schema: 1, author: 1, changes: 1, discussionOpenedBy: 1, discussionClosedBy: 1, descriptionMentions: 1, closingNoteMentions: 1}, (document) =>
      followers = []

      followers = addFollower followers, document.author, Discussion.REASON.AUTHOR
      followers = addFollower followers, document.discussionOpenedBy, Discussion.REASON.PARTICIPATED if document.discussionOpenedBy
      for user in document.descriptionMentions or []
        followers = addFollower followers, user, Discussion.REASON.MENTIONED
      for change in document.changes or []
        followers = addFollower followers, change.author, Discussion.REASON.PARTICIPATED if change.author
      followers = addFollower followers, document.discussionClosedBy, Discussion.REASON.PARTICIPATED if document.discussionClosedBy
      for user in document.closingNoteMentions or []
        followers = addFollower followers, user, Discussion.REASON.MENTIONED

      for documentClass in [Comment, Point, Motion]
        documentClass.documents.find(
          'discussion._id': document._id
        ,
          sort:
            # The oldest first.
            createdAt: 1
        ).forEach (doc, i, cursor) =>
          followers = addFollower followers, doc.author, Discussion.REASON.PARTICIPATED
          for user in doc.bodyMentions or []
            followers = addFollower followers, user, Discussion.REASON.MENTIONED

      count += collection.update
        _id: document._id
        _schema: document._schema
        followers:
          $exists: false
      ,
        $set:
          followers: followers
          _schema: newSchema

    counts = super
    counts.migrated += count
    counts.all += count
    counts

  backward: (document, collection, currentSchema, oldSchema) =>
    update =
      $unset:
        followers: ''
      $set:
        _schema: oldSchema

    count = collection.update {_schema: currentSchema}, update, {multi: true}

    counts = super
    counts.migrated += count
    counts.all += count
    counts

Discussion.addMigration new Migration()
