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

    votes = Vote.documents.find('motion._id': motion._id).map (vote, index, cursor) ->
      vote.value

    computedAt = new Date()

    # TODO: Get all users with voting role?
    populationSize = 10 # User.documents.count()

    result = VotingEngine.computeTally motion.majority, votes, populationSize

    documentId = Tally.documents.insert
      createdAt: computedAt
      version: @constructor.COMPUTE_TALLY_VERSION
      motion:
        _id: motion._id
      job:
        _id: @_id
      majority: motion.majority
      populationSize: populationSize
      votesCount: result.votesCount
      abstentionsCount: result.abstentionsCount
      inFavorVotesCount: result.inFavorVotesCount
      againstVotesCount: result.againstVotesCount
      confidenceLevel: result.confidenceLevel
      result: result.result

    assert documentId

    tally:
      _id: documentId
