# New Activity types we have until now:
# - mention: we will not have a migration because there were not available before this migration anyway
# - commentCreated, pointCreated, motionCreated
# - commentUpvoted, pointUpvoted, motionUpvoted
# - discussionCreated
# - discussionClosed
# - meetingCreated
# - motionOpened
# - competingMotionOpened
# - motionClosed
# - votedMotionClosed
# - motionWithdrawn

# These migrations are data migrations and not schema migrations. We add new documents, not really change a schema.

class UpvotableCreatedMigration extends Document.PatchMigration
  name: "Creating created activity for upvotable"

  forward: (documentClass, collection, currentSchema, newSchema) =>
    count = 0

    collection.findEach {_schema: currentSchema}, {_schema: 1, author: 1, createdAt: 1, discussion: 1}, (document) =>
      discussion = Discussion.documents.findOne document.discussion._id,
        fields:
          followers: 1

      data =
        discussion:
          _id: discussion._id
      data["#{documentClass.Meta._name.toLowerCase()}"] =
        _id: document._id

      {numberAffected, insertedId} = Activity.documents.upsert
        timestamp: document.createdAt
        'byUser._id': document.author._id
        level: Activity.LEVEL.GENERAL
        type: "#{documentClass.Meta._name.toLowerCase()}Created"
        'data.discussion._id': discussion._id
        "data.#{documentClass.Meta._name.toLowerCase()}._id": document._id
      ,
        $setOnInsert:
          byUser:
            _id: document.author._id
          forUsers: _.uniq _.pluck(discussion.followers, 'user'), (u) -> u._id
          data: data

      if insertedId
        count += collection.update
          _id: document._id
          _schema: document._schema
        ,
          $set:
            _schema: newSchema

    if count
      # Because we do not have proper byUser references we have to populate fields later.
      # But migrations run before observers are ready.
      @updateAll()

    counts = super
    counts.migrated += count
    counts.all += count
    counts

  backward: (document, collection, currentSchema, oldSchema) =>
    count = 0

    collection.findEach {_schema: currentSchema}, {_schema: 1, author: 1, createdAt: 1, discussion: 1}, (document) =>
      removed = Activity.documents.remove
        timestamp: document.createdAt
        'byUser._id': document.author._id
        level: Activity.LEVEL.GENERAL
        type: "#{documentClass.Meta._name.toLowerCase()}Created"
        'data.discussion._id': document.discussion._id
        "data.#{documentClass.Meta._name.toLowerCase()}._id": document._id

      if removed
        count += collection.update
          _id: document._id
          _schema: document._schema
        ,
          $set:
            _schema: oldSchema

    counts = super
    counts.migrated += count
    counts.all += count
    counts

Comment.addMigration new UpvotableCreatedMigration()
Point.addMigration new UpvotableCreatedMigration()
Motion.addMigration new UpvotableCreatedMigration()

class UpvotableUpvotedMigration extends Document.PatchMigration
  name: "Creating upvoted activity for upvotable"

  forward: (documentClass, collection, currentSchema, newSchema) =>
    count = 0

    collection.findEach {_schema: currentSchema}, {_schema: 1, author: 1, createdAt: 1, discussion: 1, upvotes: 1}, (document) =>
      anyUpvoted = false

      for upvote in document.upvotes or []
        data =
          discussion:
            _id: document.discussion._id
        data["#{documentClass.Meta._name.toLowerCase()}"] =
          _id: document._id

        {numberAffected, insertedId} = Activity.documents.upsert
          timestamp: upvote.createdAt
          'byUser._id': upvote.author._id
          level: Activity.LEVEL.USER
          type: "#{documentClass.Meta._name.toLowerCase()}Upvoted"
          'data.discussion._id': document.discussion._id
          "data.#{documentClass.Meta._name.toLowerCase()}._id": document._id
        ,
          $setOnInsert:
            byUser:
              _id: upvote.author._id
            forUsers: [
              _id: document.author._id
            ]
            data: data

        if insertedId
          anyUpvoted = true

      if anyUpvoted
        count += collection.update
          _id: document._id
          _schema: document._schema
        ,
          $set:
            _schema: newSchema

    if count
      # Because we do not have proper byUser references we have to populate fields later.
      # But migrations run before observers are ready.
      @updateAll()

    counts = super
    counts.migrated += count
    counts.all += count
    counts

  backward: (document, collection, currentSchema, oldSchema) =>
    count = 0

    collection.findEach {_schema: currentSchema}, {_schema: 1, author: 1, createdAt: 1, discussion: 1, upvotes: 1}, (document) =>
      anyUpvoted = false

      for upvote in document.upvotes or []
        removed = Activity.documents.remove
          timestamp: upvote.createdAt
          'byUser._id': upvote.author._id
          level: Activity.LEVEL.USER
          type: "#{documentClass.Meta._name.toLowerCase()}Upvoted"
          'data.discussion._id': document.discussion._id
          "data.#{documentClass.Meta._name.toLowerCase()}._id": document._id

        if removed
          anyUpvoted = true

      if anyUpvoted
        count += collection.update
          _id: document._id
          _schema: document._schema
        ,
          $set:
            _schema: oldSchema

    if count
      # Because we do not have proper byUser references we have to populate fields later.
      # But migrations run before observers are ready.
      @updateAll()

    counts = super
    counts.migrated += count
    counts.all += count
    counts

Comment.addMigration new UpvotableUpvotedMigration()
Point.addMigration new UpvotableUpvotedMigration()
Motion.addMigration new UpvotableUpvotedMigration()

class DiscussionCreatedMigration extends Document.PatchMigration
  name: "Creating created activity for discussion"

  forward: (documentClass, collection, currentSchema, newSchema) =>
    count = 0

    collection.findEach {_schema: currentSchema}, {_schema: 1, author: 1, createdAt: 1, title: 1}, (document) =>
      {numberAffected, insertedId} = Activity.documents.upsert
        timestamp: document.createdAt
        'byUser._id': document.author._id
        level: Activity.LEVEL.GENERAL
        type: 'discussionCreated'
        'data.discussion._id': document._id
      ,
        $setOnInsert:
          byUser:
            _id: document.author._id
          data:
            discussion:
              _id: document._id
              title: document.title

      if insertedId
        count += collection.update
          _id: document._id
          _schema: document._schema
        ,
          $set:
            _schema: newSchema

    if count
      # Because we do not have proper byUser references we have to populate fields later.
      # But migrations run before observers are ready.
      @updateAll()

    counts = super
    counts.migrated += count
    counts.all += count
    counts

  backward: (document, collection, currentSchema, oldSchema) =>
    count = 0

    collection.findEach {_schema: currentSchema}, {_schema: 1, author: 1, createdAt: 1}, (document) =>
      removed = Activity.documents.remove
        timestamp: document.createdAt
        'byUser._id': document.author._id
        level: Activity.LEVEL.GENERAL
        type: 'discussionCreated'
        'data.discussion._id': document._id

      if removed
        count += collection.update
          _id: document._id
          _schema: document._schema
        ,
          $set:
            _schema: oldSchema

    counts = super
    counts.migrated += count
    counts.all += count
    counts

Discussion.addMigration new DiscussionCreatedMigration()

class DiscussionClosedMigration extends Document.PatchMigration
  name: "Creating closed activity for discussion"

  forward: (documentClass, collection, currentSchema, newSchema) =>
    count = 0

    collection.findEach {_schema: currentSchema, discussionClosedAt: {$ne: null}, discussionClosedBy: {$ne: null}}, {_schema: 1, discussionClosedBy: 1, discussionClosedAt: 1, followers: 1, title: 1}, (document) =>
      {numberAffected, insertedId} = Activity.documents.upsert
        timestamp: document.discussionClosedAt
        'byUser._id': document.discussionClosedBy._id
        level: Activity.LEVEL.GENERAL
        type: 'discussionClosed'
        'data.discussion._id': document._id
      ,
        $setOnInsert:
          byUser:
            _id: document.discussionClosedBy._id
          forUsers: _.uniq _.pluck(document.followers, 'user'), (u) -> u._id
          data:
            discussion:
              _id: document._id
              title: document.title

      if insertedId
        count += collection.update
          _id: document._id
          _schema: document._schema
        ,
          $set:
            _schema: newSchema

    if count
      # Because we do not have proper byUser references we have to populate fields later.
      # But migrations run before observers are ready.
      @updateAll()

    counts = super
    counts.migrated += count
    counts.all += count
    counts

  backward: (document, collection, currentSchema, oldSchema) =>
    count = 0

    collection.findEach {_schema: currentSchema, discussionClosedAt: {$ne: null}, discussionClosedBy: {$ne: null}}, {_schema: 1, discussionClosedBy: 1, discussionClosedAt: 1}, (document) =>
      removed = Activity.documents.remove
        timestamp: document.discussionClosedAt
        'byUser._id': document.discussionClosedBy._id
        level: Activity.LEVEL.GENERAL
        type: 'discussionClosed'
        'data.discussion._id': document._id

      if removed
        count += collection.update
          _id: document._id
          _schema: document._schema
        ,
          $set:
            _schema: oldSchema

    counts = super
    counts.migrated += count
    counts.all += count
    counts

Discussion.addMigration new DiscussionClosedMigration()

class MeetingCreatedMigration extends Document.PatchMigration
  name: "Creating created activity for meeting"

  forward: (documentClass, collection, currentSchema, newSchema) =>
    count = 0

    collection.findEach {_schema: currentSchema}, {_schema: 1, author: 1, createdAt: 1, title: 1}, (document) =>
      {numberAffected, insertedId} = Activity.documents.upsert
        timestamp: document.createdAt
        'byUser._id': document.author._id
        level: Activity.LEVEL.GENERAL
        type: 'meetingCreated'
        'data.meeting._id': document._id
      ,
        $setOnInsert:
          byUser:
            _id: document.author._id
          data:
            meeting:
              _id: document._id
              title: document.title

      if insertedId
        count += collection.update
          _id: document._id
          _schema: document._schema
        ,
          $set:
            _schema: newSchema

    if count
      # Because we do not have proper byUser references we have to populate fields later.
      # But migrations run before observers are ready.
      @updateAll()

    counts = super
    counts.migrated += count
    counts.all += count
    counts

  backward: (document, collection, currentSchema, oldSchema) =>
    count = 0

    collection.findEach {_schema: currentSchema}, {_schema: 1, author: 1, createdAt: 1}, (document) =>
      removed = Activity.documents.remove
        timestamp: document.createdAt
        'byUser._id': document.author._id
        level: Activity.LEVEL.GENERAL
        type: 'meetingCreated'
        'data.meeting._id': document._id

      if removed
        count += collection.update
          _id: document._id
          _schema: document._schema
        ,
          $set:
            _schema: oldSchema

    counts = super
    counts.migrated += count
    counts.all += count
    counts

Meeting.addMigration new MeetingCreatedMigration()

class MotionMigration extends Document.PatchMigration
  name: "Creating activity for motion"

  forward: (documentClass, collection, currentSchema, newSchema) =>
    count = 0

    collection.findEach {_schema: currentSchema}, {_schema: 1, discussion: 1, votingOpenedBy: 1, votingOpenedAt: 1, votingClosedBy: 1, votingClosedAt: 1, withdrawnBy: 1, withdrawnAt: 1}, (document) =>
      hasActivity = false

      discussion = Discussion.documents.findOne document.discussion._id,
        fields:
          followers: 1

      if document.votingOpenedBy and document.votingOpenedAt
        {numberAffected, insertedId} = Activity.documents.upsert
          timestamp: document.votingOpenedAt
          'byUser._id': document.votingOpenedBy._id
          level: Activity.LEVEL.GENERAL
          type: 'motionOpened'
          'data.discussion._id': discussion._id
          'data.motion._id': document._id
        ,
          $setOnInsert:
            byUser:
              _id: document.votingOpenedBy._id
            forUsers: _.uniq _.pluck(discussion.followers, 'user'), (u) -> u._id
            data:
              discussion:
                _id: discussion._id
              motion:
                _id: document._id

        if insertedId
          hasActivity = true

        competingVoters = _.pluck Vote.documents.find(
          'motion._id':
            $ne: document._id
          'motion.discussion._id': discussion._id
          # Author can be null if user was deleted in meantime.
          author:
            $ne: null
          # Only votes which were made for other motions before this motion was opened.
          createdAt:
            $lte: document.votingOpenedAt
        ,
          fields:
            author: 1
        ).fetch(), 'author'

        {numberAffected, insertedId} = Activity.documents.upsert
          timestamp: document.votingOpenedAt
          'byUser._id': document.votingOpenedBy._id
          level: Activity.LEVEL.USER
          type: 'competingMotionOpened'
          'data.discussion._id': discussion._id
          'data.motion._id': document._id
        ,
          $setOnInsert:
            byUser:
              _id: document.votingOpenedBy._id
            forUsers: _.uniq competingVoters, (u) -> u._id
            data:
              discussion:
                _id: discussion._id
              motion:
                _id: document._id

        if insertedId
          hasActivity = true

      if document.votingClosedBy and document.votingClosedAt
        {numberAffected, insertedId} = Activity.documents.upsert
          timestamp: document.votingClosedAt
          'byUser._id': document.votingClosedBy._id
          level: Activity.LEVEL.GENERAL
          type: 'motionClosed'
          'data.discussion._id': discussion._id
          'data.motion._id': document._id
        ,
          $setOnInsert:
            byUser:
              _id: document.votingClosedBy._id
            forUsers: _.uniq _.pluck(discussion.followers, 'user'), (u) -> u._id
            data:
              discussion:
                _id: discussion._id
              motion:
                _id: document._id

        if insertedId
          hasActivity = true

        voters = _.pluck Vote.documents.find(
          'motion._id': document._id
          # Author can be null if user was deleted in meantime.
          author:
            $ne: null
        ,
          fields:
            author: 1
        ).fetch(), 'author'

        {numberAffected, insertedId} = Activity.documents.upsert
          timestamp: document.votingClosedAt
          'byUser._id': document.votingClosedBy._id
          level: Activity.LEVEL.USER
          type: 'votedMotionClosed'
          'data.discussion._id': discussion._id
          'data.motion._id': document._id
        ,
          $setOnInsert:
            byUser:
              _id: document.votingClosedBy._id
            forUsers: _.uniq voters, (u) -> u._id
            data:
              discussion:
                _id: discussion._id
              motion:
                _id: document._id

        if insertedId
          hasActivity = true

      if document.withdrawnBy and document.withdrawnAt
        {numberAffected, insertedId} = Activity.documents.upsert
          timestamp: document.withdrawnAt
          'byUser._id': document.withdrawnBy._id
          level: Activity.LEVEL.GENERAL
          type: 'motionWithdrawn'
          'data.discussion._id': discussion._id
          'data.motion._id': document._id
        ,
          $setOnInsert:
            byUser:
              _id: document.withdrawnBy._id
            forUsers: _.uniq _.pluck(discussion.followers, 'user'), (u) -> u._id
            data:
              discussion:
                _id: discussion._id
              motion:
                _id: document._id

        if insertedId
          hasActivity = true

      if hasActivity
        count += collection.update
          _id: document._id
          _schema: document._schema
        ,
          $set:
            _schema: newSchema

    if count
      # Because we do not have proper byUser references we have to populate fields later.
      # But migrations run before observers are ready.
      @updateAll()

    counts = super
    counts.migrated += count
    counts.all += count
    counts

  backward: (document, collection, currentSchema, oldSchema) =>
    count = 0

    collection.findEach {_schema: currentSchema}, {_schema: 1, discussion: 1, votingOpenedBy: 1, votingOpenedAt: 1, votingClosedBy: 1, votingClosedAt: 1, withdrawnBy: 1, withdrawnAt: 1}, (document) =>
      removedActivity = false

      if document.votingOpenedBy and document.votingOpenedAt
        removed = Activity.documents.remove
          timestamp: document.votingOpenedAt
          'byUser._id': document.votingOpenedBy._id
          $or: [
            level: Activity.LEVEL.GENERAL
            type: 'motionOpened'
          ,
            level: Activity.LEVEL.USER
            type: 'competingMotionOpened'
          ]
          'data.discussion._id': document.discussion._id
          'data.motion._id': document._id

        if removed
          removedActivity = true

      if document.votingClosedBy and document.votingClosedAt
        removed = Activity.documents.remove
          timestamp: document.votingClosedAt
          'byUser._id': document.votingClosedBy._id
          $or: [
            level: Activity.LEVEL.GENERAL
            type: 'motionClosed'
          ,
            level: Activity.LEVEL.USER
            type: 'votedMotionClosed'
          ]
          'data.discussion._id': document.discussion._id
          'data.motion._id': document._id

        if removed
          removedActivity = true

      if document.withdrawnBy and document.withdrawnAt
        removed = Activity.documents.remove
          timestamp: document.withdrawnAt
          'byUser._id': document.withdrawnBy._id
          level: Activity.LEVEL.GENERAL
          type: 'motionWithdrawn'
          'data.discussion._id': document.discussion._id
          'data.motion._id': document._id

        if removed
          removedActivity = true

      if removedActivity
        count += collection.update
          _id: document._id
          _schema: document._schema
        ,
          $set:
            _schema: oldSchema

    counts = super
    counts.migrated += count
    counts.all += count
    counts

Motion.addMigration new MotionMigration()
