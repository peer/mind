class VotingEngine extends VotingEngine
  @isInteger: (value) ->
    _.isNumber(value) && _.isFinite(value) && value is Math.round(value)

  @combinations: (n, k) ->
    assert @isInteger(n), n
    assert @isInteger(k), k
    assert 0 <= k <= n, JSON.stringify {k, n}

    max = Math.max(k, n - k)
    result = 1
    for i in [1..n - max] by +1
      result *= (max + i) / i
    result

  @binomialProbabilityMass: (k, n, p) ->
    assert @isInteger(n), n
    assert @isInteger(k), k
    assert 0 <= k <= n, JSON.stringify {k, n}

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
    assert votes.length <= populationSize, JSON.stringify {length: votes.length, populationSize}

    votesCount = 0
    abstentionsCount = 0
    confidenceLevel = 0
    confidenceIntervalLowerBound = -1
    confidenceIntervalUpperBound = 1
    result = 0

    for vote in votes
      if vote is @VALUE.ABSTAIN
        abstentionsCount++
      else if vote is @VALUE.DEFAULT
        # We do not do anything. It is the same as vote not cast.
      else if _.isNumber(vote) and -1 <= vote <= 1
        votesCount++
        # Summing all normalized votes.
        result += (vote + 1) / 2
      else
        throw new Error "Invalid vote value: '#{vote}'"

    if votesCount > 0
      # Result is an average.
      result /= votesCount

    assert 0 <= result <= 1, result

    majorityResult = Math.max(result, 1 - result)

    effectivePopulationSize = populationSize - abstentionsCount
    nonvotersCount = effectivePopulationSize - votesCount

    if majority is @MAJORITY.SIMPLE
      threshold = effectivePopulationSize / 2
    else if majority is @MAJORITY.SUPER
      threshold = effectivePopulationSize * 2 / 3
    else
      assert false, majority

    if effectivePopulationSize > 0
      bias = (Math.floor(threshold) + 1) / effectivePopulationSize
      lowerBound = Math.max(Math.ceil(threshold - votesCount * majorityResult), 0)
      upperBound = nonvotersCount

      assert 0.0 <= bias <= 1.0, bias

      confidenceLevel = @sumBinomialProbabilityMass lowerBound, upperBound, nonvotersCount, bias

      neededVotes = 0
      loop
        lowerBound = Math.ceil(bias * nonvotersCount - neededVotes)
        upperBound = Math.floor(bias * nonvotersCount + neededVotes)

        if upperBound > nonvotersCount
          # Solution not found, setting maximum possible needed votes.
          neededVotes = nonvotersCount
          break

        break if @sumBinomialProbabilityMass(lowerBound, upperBound, nonvotersCount, bias) >= 0.90

        neededVotes++

    if votesCount > 0
      confidenceIntervalLowerBound = Math.max(0, (votesCount * result + bias * nonvotersCount - neededVotes) / effectivePopulationSize)
      confidenceIntervalUpperBound = Math.min(1, (votesCount * result + bias * nonvotersCount + neededVotes) / effectivePopulationSize)

      # Rescale.
      result = result * 2 - 1
      confidenceIntervalLowerBound = confidenceIntervalLowerBound * 2 - 1
      confidenceIntervalUpperBound = confidenceIntervalUpperBound * 2 - 1

    {
      populationSize
      votesCount
      abstentionsCount
      confidenceLevel
      confidenceIntervalLowerBound
      confidenceIntervalUpperBound
      result
    }
