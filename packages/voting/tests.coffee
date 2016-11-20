class VotingTestCase extends ClassyTestCase
  @testName: 'voting'

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
      confidenceIntervalLowerBound: 0.19999999999999996
      confidenceIntervalUpperBound: 1
      result: 1

    @assertEqual VotingEngine.computeTally(VotingEngine.MAJORITY.SIMPLE, ['abstain', 'abstain', 'abstain', 'abstain', 'abstain', 1.0, 1.0, -1.0], 10),
      populationSize: 10
      votesCount: 3
      abstentionsCount: 5
      confidenceLevel: 0.84
      confidenceIntervalLowerBound: -0.19999999999999996
      confidenceIntervalUpperBound: 0.6000000000000001
      result: 0.33333333333333326

    @assertEqual VotingEngine.computeTally(VotingEngine.MAJORITY.SIMPLE, ['abstain', 'abstain', 'abstain', 'abstain', 'abstain', 1.0, 1.0, -1.0, 'default', 'default'], 10),
      populationSize: 10
      votesCount: 3
      abstentionsCount: 5
      confidenceLevel: 0.84
      confidenceIntervalLowerBound: -0.19999999999999996
      confidenceIntervalUpperBound: 0.6000000000000001
      result: 0.33333333333333326

    @assertEqual VotingEngine.computeTally(VotingEngine.MAJORITY.SIMPLE, ['abstain', 'abstain', 'abstain', 'abstain', 'abstain', 1.0, 1.0, -1.0, 1.0], 10),
      populationSize: 10
      votesCount: 4
      abstentionsCount: 5
      confidenceLevel: 1
      confidenceIntervalLowerBound: 0.0
      confidenceIntervalUpperBound: 0.8
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
      confidenceIntervalLowerBound: -0.13157894736842102
      confidenceIntervalUpperBound: 0.5
      result: 0.3500000000000001

    @assertEqual VotingEngine.computeTally(VotingEngine.MAJORITY.SIMPLE, ['abstain', 'abstain', 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, -1.0, -1.0, 0.5], 13),
      populationSize: 13
      votesCount: 9
      abstentionsCount: 2
      confidenceLevel: 0.7933884297520661
      confidenceIntervalLowerBound: -0.13636363636363635
      confidenceIntervalUpperBound: 0.2272727272727273
      result: 0.05555555555555558

    @assertEqual VotingEngine.computeTally(VotingEngine.MAJORITY.SIMPLE, ['abstain', 'abstain', 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, -1.0, -1.0, 0.5, 1.0], 13),
      populationSize: 13
      votesCount: 10
      abstentionsCount: 2
      confidenceLevel: 1
      confidenceIntervalLowerBound: -0.045454545454545414
      confidenceIntervalUpperBound: 0.3181818181818181
      result: 0.1499999999999999

    @assertEqual VotingEngine.computeTally(VotingEngine.MAJORITY.SIMPLE, ['abstain', 'abstain', 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, -1.0, -1.0, 0.5, 1.0, 1.0], 13),
      populationSize: 13
      votesCount: 11
      abstentionsCount: 2
      confidenceLevel: 1
      confidenceIntervalLowerBound: 0.2272727272727273
      confidenceIntervalUpperBound: 0.2272727272727273
      result: 0.2272727272727273

    @assertEqual VotingEngine.computeTally(VotingEngine.MAJORITY.SUPER, ['abstain', -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, 0.5, 0.5, 1.0], 20),
      populationSize: 20
      votesCount: 10
      abstentionsCount: 1
      confidenceLevel: 0.6927864321251747
      confidenceIntervalLowerBound: -0.631578947368421
      confidenceIntervalUpperBound: -0.21052631578947367
      result: -0.5

    @assertEqual VotingEngine.computeTally(VotingEngine.MAJORITY.SIMPLE, [1.0, 1.0, 1.0, 1.0, 1.0, -1.0, 1.0, 1.0, 1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0, 'abstain', 1.0, 1.0, 1.0, 1.0], 143),
      populationSize: 143
      votesCount: 19
      abstentionsCount: 1
      confidenceLevel: 0.9220827379421381
      confidenceIntervalLowerBound: -0.04929577464788737
      confidenceIntervalUpperBound: 0.232394366197183
      result: 0.6842105263157894

ClassyTestCase.addTest new VotingTestCase()
