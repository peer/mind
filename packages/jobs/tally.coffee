class ComputeTallyJob extends Job
  @register()

  run: ->
    # We are loading packages in unordered mode, so we are fixing imports here, if needed.
    User = Package.core.User unless User
    Vote = Package.core.Vote unless Vote
    Tally = Package.core.Tally unless Tally
    Motion = Package.core.Motion unless Motion
    VotingEngine = Package.voting.VotingEngine unless VotingEngine

    motion = Motion.documents.findOne @data.motion._id

    throw new Error ("Motion '#{@data.motion._id}' does not exist.") unless motion

    throw new Error ("Motion '#{@data.motion._id}' is not open for voting.") unless motion.isOpen()

    votes = Vote.documents.find('motion._id': motion._id,
      fields:
        _id: 1
        value: 1
    ).fetch()

    votesValues = _.pluck votes, 'value'

    computedAt = new Date()

    populationSize = User.withPermission(User.PERMISSIONS.MOTION_VOTE).count()

    result = VotingEngine.computeTally motion.majority, votesValues, populationSize

    # Some votes might be abstentions or nothing votes.
    assert result.votesCount <= votes.length, JSON.stringify {votesCount: result.votesCount, length: votes.length}

    # In stored documents we use shorter field names so that less data has to stored and be transferred to the client.
    documentId = Tally.documents.insert
      createdAt: computedAt
      version: VotingEngine.VERSION
      motion:
        _id: motion._id
      votes: (_.pick vote, '_id' for vote in votes)
      votesCount: result.votesCount
      job:
        _id: @_id
      majority: motion.majority
      population: populationSize
      abstentions: result.abstentionsCount
      confidence: result.confidenceLevel
      confidenceLower: result.confidenceIntervalLowerBound
      confidenceUpper: result.confidenceIntervalUpperBound
      result: result.result

    assert documentId

    tally:
      _id: documentId
