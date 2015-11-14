class Tally extends share.BaseDocument
  # createdAt: time of document creation
  # version: version of the tally computing code which computed this tally
  # motion: tally is for this motion
  #   _id
  # votes: list of votes used to compute this tally
  #   _id
  # votesCount: votes count (it is not a generator on purpose, so that the document is not modified after it is created)
  # job: job which computed this tally
  #   _id:
  # majority: one of Motion.MAJORITY values
  # population: population size
  # abstentions: abstentions count
  # inFavor: in favor votes count
  # against: against votes count
  # confidence: confidence level
  # confidenceLower: confidence interval lower bound
  # confidenceUpper: confidence interval upper bound
  # result

  @Meta
    name: 'Tally'
    collection: 'Tallies'
    fields: =>
      motion: @ReferenceField Motion
      votes: [@ReferenceField Vote]
      job: @ReferenceField JobQueue

  @PUBLISH_FIELDS: ->
    createdAt: 1
    motion: 1
    votesCount: 1
    population: 1
    abstentions: 1
    confidence: 1
    confidenceLower: 1
    confidenceUpper: 1
    result: 1

if Meteor.isServer
  Tally.Meta.collection._ensureIndex
    createdAt: 1
