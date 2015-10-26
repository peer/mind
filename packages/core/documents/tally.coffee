class Tally extends share.BaseDocument
  # createdAt: time of document creation
  # motion: tally is for this motion
  #  _id
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
