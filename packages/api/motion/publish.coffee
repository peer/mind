new PublishEndpoint 'Motion.list', (discussionId) ->
  check discussionId, Match.DocumentId

  Motion.documents.find
    'discussion._id': discussionId
  ,
    fields: Motion.PUBLISH_FIELDS()

new PublishEndpoint 'Motion.vote', (motionId) ->
  check motionId, Match.DocumentId

  return @ready() unless @userId

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
