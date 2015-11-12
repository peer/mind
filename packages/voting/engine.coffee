class VotingEngine extends VotingEngine
  @isInteger: (value) ->
	  _.isNumber(value) && _.isFinite(value) && value is Math.round(value)

  @combinations: (n, k) ->
    assert @isInteger(n), n
    assert @isInteger(k), k
    assert k <= n, {k, n}

    max = Math.max(k, n - k)
    result = 1
    for i in [1..n - max] by +1
      result *= (max + i) / i
    result

  @computeTally: (majority, votes, populationSize) ->
    # We are loading packages in unordered mode, so we are fixing imports here, if needed.
    Motion = Package.core.Motion unless Motion

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

    if votesCount > 0
      result = (inFavorVotesCount / votesCount) * 2 - 1
    else
      result = 0

    effectivePopulationSize = populationSize - abstentionsCount

    if majority is Motion.MAJORITY.SIMPLE
      threshold = Math.floor(effectivePopulationSize / 2)
    else if majority is Motion.MAJORITY.SUPER
      threshold = Math.floor(effectivePopulationSize * 2 / 3)
    else
      assert false, majority

    bias = (threshold + 1) / effectivePopulationSize
    upperBound = effectivePopulationSize - votesCount
    lowerBound = Math.ceil(threshold - majorityVotesCount + 1)

    confidenceLevel = 0
    for k in [lowerBound..upperBound] by +1
      confidenceLevel += @combinations(effectivePopulationSize - votesCount, k) * Math.pow(bias, k) * Math.pow(1 - bias, effectivePopulationSize - votesCount - k)

    {
      populationSize
      votesCount
      abstentionsCount
      inFavorVotesCount
      againstVotesCount
      confidenceLevel
      result
    }
