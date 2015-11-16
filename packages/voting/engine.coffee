class VotingEngine extends VotingEngine
  @isInteger: (value) ->
    _.isNumber(value) && _.isFinite(value) && value is Math.round(value)

  @combinations: (n, k) ->
    assert @isInteger(n), n
    assert @isInteger(k), k
    assert 0 <= k <= n, {k, n}

    max = Math.max(k, n - k)
    result = 1
    for i in [1..n - max] by +1
      result *= (max + i) / i
    result

  @binomialProbabilityMass: (k, n, p) ->
    assert @isInteger(n), n
    assert @isInteger(k), k
    assert 0 <= k <= n, {k, n}

    @combinations(n, k) * Math.pow(p, k) * Math.pow(1 - p, n - k)

  @sumBinomialProbabilityMass: (lowerBound, upperBound, n, p) ->
    assert @isInteger(lowerBound), lowerBound
    assert @isInteger(upperBound), upperBound
    assert @isInteger(n), n
    assert 0 <= n, n

    result = 0
    for k in [lowerBound..upperBound] by +1
      result += @binomialProbabilityMass k, n, p
    result

  @computeTally: (majority, votes, populationSize) ->
    votesCount = 0
    abstentionsCount = 0
    inFavorVotesCount = 0
    againstVotesCount = 0

    for vote in votes
      if vote is @VALUE.ABSTAIN
        abstentionsCount++
      else if vote is @VALUE.DEFAULT
        # We do not do anything. It is the same as vote not cast.
      else if _.isNumber(vote) and -1 <= vote <= 1
        votesCount++
        inFavor = (vote + 1) / 2
        against = 1 - inFavor
        inFavorVotesCount += inFavor
        againstVotesCount += against
      else
        throw new Error "Invalid vote value: '#{vote}'"

    assert inFavorVotesCount >= 0, inFavorVotesCount
    assert againstVotesCount >= 0, againstVotesCount

    assert.equal inFavorVotesCount + againstVotesCount, votesCount

    majorityVotesCount = Math.max(inFavorVotesCount, againstVotesCount)

    effectivePopulationSize = populationSize - abstentionsCount

    if majority is @MAJORITY.SIMPLE
      threshold = Math.floor(effectivePopulationSize / 2)
    else if majority is @MAJORITY.SUPER
      threshold = Math.floor(effectivePopulationSize * 2 / 3)
    else
      assert false, majority

    bias = (threshold + 1) / effectivePopulationSize
    lowerBound = Math.ceil(threshold - majorityVotesCount + 1)
    upperBound = effectivePopulationSize - votesCount

    confidenceLevel = @sumBinomialProbabilityMass lowerBound, upperBound, effectivePopulationSize - votesCount, bias

    neededVotes = 0
    loop
      lowerBound = Math.ceil(bias * (effectivePopulationSize - votesCount) - neededVotes)
      upperBound = Math.floor(bias * (effectivePopulationSize - votesCount) + neededVotes)

      break if @sumBinomialProbabilityMass(lowerBound, upperBound, effectivePopulationSize - votesCount, bias) >= 0.90

      neededVotes++

    if votesCount > 0
      confidenceIntervalLowerBound = Math.max(-1, ((inFavorVotesCount - neededVotes) / votesCount) * 2 - 1)
      confidenceIntervalUpperBound = Math.min(1, ((inFavorVotesCount + neededVotes) / votesCount) * 2 - 1)
      result = (inFavorVotesCount / votesCount) * 2 - 1
    else
      confidenceIntervalLowerBound = -1
      confidenceIntervalUpperBound = 1
      result = 0

    {
      populationSize
      votesCount
      abstentionsCount
      inFavorVotesCount
      againstVotesCount
      confidenceLevel
      confidenceIntervalLowerBound
      confidenceIntervalUpperBound
      result
    }
