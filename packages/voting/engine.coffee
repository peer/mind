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
      probability = 1 / 2
      threshold = effectivePopulationSize * probability
    else if majority is @MAJORITY.SUPER
      # Majority result is in favor.
      if majorityResult is result
        probability = 2 / 3
      # Majority result is opposing.
      else
        probability = 1 / 3
      threshold = effectivePopulationSize * probability
    else
      assert false, majority

    if effectivePopulationSize > 0
      # We assume here that the population has a slight bias (one person) towards the majority and not
      # that it is completely 50/50 split. If the latter is wanted, "probability" could be used directly.
      # This slight bias lowers the quorum a bit because we observed that it aligns better with what
      # one would expect for quorum to be given a population size and votes.
      bias = (Math.floor(threshold) + 1) / effectivePopulationSize
      lowerBound = Math.max(Math.ceil(threshold - votesCount * majorityResult), 0)
      upperBound = nonvotersCount

      assert 0.0 <= bias <= 1.0, bias

      confidenceLevel = @sumBinomialProbabilityMass lowerBound, upperBound, nonvotersCount, bias

      # We compute confidence interval numerically by searching for a solution to how many more votes are
      # needed for 0.90 confidence. Fo this we are using directly "probability" and not "bias".
      neededVotes = 0
      loop
        lowerBound = Math.ceil(probability * nonvotersCount - neededVotes)
        upperBound = Math.floor(probability * nonvotersCount + neededVotes)

        if upperBound > nonvotersCount
          # Solution not found, setting maximum possible needed votes.
          neededVotes = nonvotersCount
          break

        break if @sumBinomialProbabilityMass(lowerBound, upperBound, nonvotersCount, probability) >= 0.90

        neededVotes++

    if votesCount > 0
      confidenceIntervalLowerBound = Math.max(0, (votesCount * majorityResult + probability * nonvotersCount - neededVotes) / effectivePopulationSize)
      confidenceIntervalUpperBound = Math.min(1, (votesCount * majorityResult + probability * nonvotersCount + neededVotes) / effectivePopulationSize)

      # We have to reverse and shift the interval if we majorityResult is leaning towards 0 (-1 rescaled).
      if result isnt majorityResult
        [confidenceIntervalLowerBound, confidenceIntervalUpperBound] = [1 - confidenceIntervalUpperBound, 1 - confidenceIntervalLowerBound]

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
