class Tally extends share.BaseDocument
  # createdAt: time of document creation
  # motion: tally is for this motion
  #   _id
  # job: job which computed this tally
  #   _id:
  # populationSize
  # votesCount
  # abstentionsCount
  # inFavorVotesCount
  # againstVotesCount
  # confidenceLevel
  # result

  @Meta
    name: 'Tally'
    collection: 'Tallies'
    fields: =>
      motion: @ReferenceField Motion
      job: @ReferenceField JobQueue

  @PUBLISH_FIELDS: ->
    createdAt: 1
    motion: 1
    populationSize: 1
    votesCount: 1
    abstentionsCount: 1
    confidenceLevel: 1
    result: 1
