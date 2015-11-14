class ComputeTallyJob extends Job
  @COMPUTE_TALLY_VERSION: '0.1.0'

  @register()

  run: ->
    # We are loading packages in unordered mode, so we are fixing imports here, if needed.
    Vote = Package.core.Vote unless Vote
    Tally = Package.core.Tally unless Tally
    Motion = Package.core.Motion unless Motion
    VotingEngine = Package.voting.VotingEngine unless VotingEngine

    motion = Motion.documents.findOne @data.motion._id,
      fields:
        majority: 1

    assert motion.majority

    throw new Error ("Motion '#{@data.motion._id}' does not exist.") unless motion

    votes = Vote.documents.find('motion._id': motion._id,
      fields:
        _id: 1
        value: 1
    ).fetch()

    votesValues = _.pluck votes, 'value'

    computedAt = new Date()

    # TODO: Get all users with voting role?
    populationSize = 10 # User.documents.count()

    result = VotingEngine.computeTally motion.majority, votesValues, populationSize

    assert.equal votes.length, result.votesCount

    # In stored documents we use shorter field names so that less data has to stored and be transferred to the client.
    documentId = Tally.documents.insert
      createdAt: computedAt
      version: @constructor.COMPUTE_TALLY_VERSION
      motion:
        _id: motion._id
      votes: (_.pick vote, '_id' for vote in votes)
      votesCount: result.votesCount
      job:
        _id: @_id
      majority: motion.majority
      population: populationSize
      abstentions: result.abstentionsCount
      inFavor: result.inFavorVotesCount
      against: result.againstVotesCount
      confidence: result.confidenceLevel
      confidenceLower: result.confidenceIntervalLowerBound
      confidenceUpper: result.confidenceIntervalUpperBound
      result: result.result

    assert documentId

    tally:
      _id: documentId
