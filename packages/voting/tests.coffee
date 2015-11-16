class VotingTestCase extends ClassyTestCase
  @testName: 'Voting'

  testIsInteger: ->
    @assertFalse VotingEngine.isInteger ''
    @assertFalse VotingEngine.isInteger '1'
    @assertFalse VotingEngine.isInteger 1.1
    @assertFalse VotingEngine.isInteger 2 / 3
    @assertTrue VotingEngine.isInteger 0
    @assertTrue VotingEngine.isInteger 1
    @assertTrue VotingEngine.isInteger 9999999
    @assertTrue VotingEngine.isInteger 0.0
    @assertTrue VotingEngine.isInteger 4 / 2
    @assertTrue VotingEngine.isInteger 9 / 3
    @assertTrue VotingEngine.isInteger 10 / 5

  testComputeTally: ->
    @assertEqual VotingEngine.computeTally(VotingEngine.MAJORITY.SIMPLE, [], 0),
      populationSize: 0
      votesCount: 0
      abstentionsCount: 0
      confidenceLevel: 0
      confidenceIntervalLowerBound: -1
      confidenceIntervalUpperBound: 1
      result: 0

    @assertEqual VotingEngine.computeTally(VotingEngine.MAJORITY.SIMPLE, [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0], 10),
      populationSize: 10
      votesCount: 10
      abstentionsCount: 0
      confidenceLevel: 1
      confidenceIntervalLowerBound: 1
      confidenceIntervalUpperBound: 1
      result: 1

    @assertEqual VotingEngine.computeTally(VotingEngine.MAJORITY.SIMPLE, [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, -1.0, -1.0, -1.0, -1.0], 10),
      populationSize: 10
      votesCount: 10
      abstentionsCount: 0
      confidenceLevel: 1
      confidenceIntervalLowerBound: 0.19999999999999996
      confidenceIntervalUpperBound: 0.19999999999999996
      result: 0.19999999999999996

    @assertEqual VotingEngine.computeTally(VotingEngine.MAJORITY.SIMPLE, [1.0, 1.0, 1.0, 1.0, 1.0, 1.0], 10),
      populationSize: 10
      votesCount: 6
      abstentionsCount: 0
      confidenceLevel: 1.0000000000000002
      confidenceIntervalLowerBound: 0.28
      confidenceIntervalUpperBound: 1
      result: 1

    @assertEqual VotingEngine.computeTally(VotingEngine.MAJORITY.SIMPLE, ['abstain', 'abstain', 'abstain', 'abstain', 'abstain', 1.0, 1.0, -1.0], 10),
      populationSize: 10
      votesCount: 3
      abstentionsCount: 5
      confidenceLevel: 0.84
      confidenceIntervalLowerBound: -0.5199999999999999
      confidenceIntervalUpperBound: 1
      result: 0.33333333333333326

    @assertEqual VotingEngine.computeTally(VotingEngine.MAJORITY.SIMPLE, ['abstain', 'abstain', 'abstain', 'abstain', 'abstain', 1.0, 1.0, -1.0, 'default', 'default'], 10),
      populationSize: 10
      votesCount: 3
      abstentionsCount: 5
      confidenceLevel: 0.84
      confidenceIntervalLowerBound: -0.5199999999999999
      confidenceIntervalUpperBound: 1
      result: 0.33333333333333326

    @assertEqual VotingEngine.computeTally(VotingEngine.MAJORITY.SIMPLE, ['abstain', 'abstain', 'abstain', 'abstain', 'abstain', 1.0, 1.0, -1.0, 1.0], 10),
      populationSize: 10
      votesCount: 4
      abstentionsCount: 5
      confidenceLevel: 1
      confidenceIntervalLowerBound: 0.040000000000000036
      confidenceIntervalUpperBound: 0.8399999999999999
      result: 0.5

    @assertEqual VotingEngine.computeTally(VotingEngine.MAJORITY.SIMPLE, ['abstain', 'abstain', 'abstain', 'abstain', 'abstain', 1.0, 1.0, -1.0, 1.0, -1.0], 10),
      populationSize: 10
      votesCount: 5
      abstentionsCount: 5
      confidenceLevel: 1
      confidenceIntervalLowerBound: 0.19999999999999996
      confidenceIntervalUpperBound: 0.19999999999999996
      result: 0.19999999999999996

    @assertEqual VotingEngine.computeTally(VotingEngine.MAJORITY.SIMPLE, ['abstain', 'abstain', 'abstain', 'abstain', 'abstain', 1.0, 1.0, -1.0, 1.0, 1.0], 10),
      populationSize: 10
      votesCount: 5
      abstentionsCount: 5
      confidenceLevel: 1
      confidenceIntervalLowerBound: 0.6000000000000001
      confidenceIntervalUpperBound: 0.6000000000000001
      result: 0.6000000000000001

    @assertEqual VotingEngine.computeTally(VotingEngine.MAJORITY.SIMPLE, [1.0, 0.0, 0.0, 1.0, -1.0, 0.5, -0.5, 1.0, 1.0, 0.5, 'abstain'], 20),
      populationSize: 20
      votesCount: 10
      abstentionsCount: 1
      confidenceLevel: 0.9334331183777842
      confidenceIntervalLowerBound: -0.10664819944598347
      confidenceIntervalUpperBound: 0.5249307479224377
      result: 0.3500000000000001

    @assertEqual VotingEngine.computeTally(VotingEngine.MAJORITY.SIMPLE, ['abstain', 'abstain', 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, -1.0, -1.0, 0.5], 13),
      populationSize: 13
      votesCount: 9
      abstentionsCount: 2
      confidenceLevel: 0.7933884297520661
      confidenceIntervalLowerBound: -0.30165289256198347
      confidenceIntervalUpperBound: 0.4256198347107438
      result: 0.05555555555555558

    @assertEqual VotingEngine.computeTally(VotingEngine.MAJORITY.SIMPLE, ['abstain', 'abstain', 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, -1.0, -1.0, 0.5, 1.0], 13),
      populationSize: 13
      votesCount: 10
      abstentionsCount: 2
      confidenceLevel: 1
      confidenceIntervalLowerBound: -0.0371900826446282
      confidenceIntervalUpperBound: 0.32644628099173545
      result: 0.1499999999999999

    @assertEqual VotingEngine.computeTally(VotingEngine.MAJORITY.SIMPLE, ['abstain', 'abstain', 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, -1.0, -1.0, 0.5, 1.0, 1.0], 13),
      populationSize: 13
      votesCount: 11
      abstentionsCount: 2
      confidenceLevel: 1
      confidenceIntervalLowerBound: 0.2272727272727273
      confidenceIntervalUpperBound: 0.2272727272727273
      result: 0.2272727272727273

ClassyTestCase.addTest new VotingTestCase()
