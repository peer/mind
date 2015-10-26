class Tally extends share.BaseDocument
  # createdAt: time of document creation
  # motion: tally is for this motion
  #   _id
  # job: job which computed this tally
  #   _id:
  # populationSize
  # votesCount
  # abstainsCount
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
