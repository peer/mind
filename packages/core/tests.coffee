class CoreTestCase extends ClassyTestCase
  @testName: 'core'

  testUserNormalizeDelegationsRandom: ->
    for i in [0..100]
      delegations = ({ratio: Random.fraction()} for j in [0..3])

      delegationsRepresentation = (delegation.ratio.toFixed(20) for delegation in delegations).join(', ')

      delegations = User.normalizeDelegations delegations

      sum = User._delegationsSum delegations

      @assertEqual sum, 1.0, delegationsRepresentation

  testUserNormalizeDelegations: ->
    TEST_CASES = [
      [0.0]
      [0.3]
      [1.0]
      [0.2, 0.8]
      [0.0, 0.5, 0.1]
      [0.0, 0.0, 0.9]
      [0.28929993489784822103, 0.31008623188441802876, 0.19065357835268603726, 0.20996025486504751867]
      [0.27449260698927169244, 0.26390952678124363073, 0.14345190180088057685, 0.31814596442860426651]
      [0.28999999999999998002, 0.28999999999999998002, 0.29999999999999998890, 0.11999999999999999556]
      [0.41999999999999998446, 0.14999999999999999445, 0.30999999999999999778, 0.13000000000000000444]
      [0.29000000000000003553, 0.29000000000000003553, 0.29999999999999982236, 0.12000000000000000944]
      [0.30693069306930698126, 0.28712871287128693965, 0.28712871287128716169, 0.11881188118811883414]
      [0.38982324752013558511, 0.51443719957727829240, 0.09155809022443191225, 0.00418146267815403243]
      [0.54096238660366224860, 0.17107742658630642474, 0.27030034536891411889, 0.01765984144111733961]
      [0.26320033473501186494, 0.27019161936339070040, 0.31776763939570407125, 0.14667319644882068075, 0.00216721005707281927]
    ]

    for testCase in TEST_CASES
      delegations = ({ratio: test} for test in testCase)

      delegationsRepresentation = (delegation.ratio.toFixed(20) for delegation in delegations).join(', ')

      delegations = User.normalizeDelegations delegations

      sum = User._delegationsSum delegations

      @assertEqual sum, 1.0, delegationsRepresentation

ClassyTestCase.addTest new CoreTestCase()
