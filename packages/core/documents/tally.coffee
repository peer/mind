class Tally extends share.BaseDocument
  # createdAt: time of document creation
  # version: version of the tally computing code which computed this tally
  # motion: tally is for this motion
  #   _id
  # job: job which computed this tally
  #   _id:
  # majority: one of Motion.MAJORITY values
  # population: population size
  # votes: votes count
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
      job: @ReferenceField JobQueue

  @PUBLISH_FIELDS: ->
    createdAt: 1
    motion: 1
    population: 1
    votes: 1
    abstentions: 1
    confidence: 1
    confidenceLower: 1
    confidenceUpper: 1
    result: 1

if Meteor.isServer
  Tally.Meta.collection._ensureIndex
    createdAt: 1
