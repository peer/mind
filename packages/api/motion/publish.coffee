new PublishEndpoint 'Motion.list', (discussionId) ->
  check discussionId, Match.DocumentId

  Motion.documents.find
    'discussion._id': discussionId
  ,
    fields: Motion.PUBLISH_FIELDS()

new PublishEndpoint 'Motion.forEdit', (motionId) ->
  check motionId, Match.DocumentId

  Motion.documents.find
    _id: motionId
  ,
    fields:
      body: 1

new PublishEndpoint 'Motion.vote', (motionId) ->
  check motionId, Match.DocumentId

  return [] unless @userId

  Vote.documents.find
    'motion._id': motionId
    'author._id': @userId
  ,
    Vote.PUBLISH_FIELDS()

new PublishEndpoint 'Motion.tally', (motionId) ->
  check motionId, Match.DocumentId

  Tally.documents.find
    'motion._id': motionId
  ,
    fields: Tally.PUBLISH_FIELDS()

new PublishEndpoint 'Motion.latestTally', (motionId) ->
  check motionId, Match.DocumentId

  Tally.documents.find
    'motion._id': motionId
  ,
    fields: Tally.PUBLISH_FIELDS()
    limit: 1
    sort:
      # The latest tally document.
      createdAt: -1
