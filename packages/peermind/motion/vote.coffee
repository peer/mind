class Motion.VoteComponent extends UIComponent
  @register 'Motion.VoteComponent'

  VALUE: Vote.VALUE

  onCreated: ->
    super

    @currentMotionId = new ComputedField =>
      @data()?._id

    @autorun (computation) =>
      motionId = @currentMotionId()
      @subscribe 'Motion.vote', motionId if motionId

    @rangeDeselected = new ReactiveField 'deselected'
    @voteValueChange = new ReactiveField null
    @_voteValueChangeByUser = false

    @autorun (computation) =>
      vote = @currentVote()

      if _.isNumber(vote?.value) and -1 <= vote.value <= 1
        @selectRange()
        @voteValueChange vote.value
      else
        @deselectRange()
        @voteValueChange vote?.value or null

    @autorun (computation) =>
      return unless @currentMotionId() and @subscriptionsReady()
      computation.stop()

      Tracker.nonreactive =>
        @observeVoteValueChange()

  onRendered: ->
    super

    @autorun (computation) =>
      # We wait until subscriptions are ready. We run this computation only once
      # after subscriptions become ready, to initialize the jQuery UI slider.
      return unless @subscriptionsReady()
      computation.stop()

      @$('.range').slider
        range: 'min'
        min: -1.0
        max: 1.0
        step: 0.25
        value: @voteValue() ? 0.0
        ticks: true
        slide: (event, ui) =>
          @$('.ui-slider-handle').text(ui.value)
          return
        change: (event, ui) =>
          @$('.ui-slider-handle').text(ui.value)
          return

      # We are stopping outside computation, but we want this one to continue.
      # We initialize this computation only after jQuery slider has been created.
      Tracker.nonreactive =>
        @autorun (computation) =>
          value = @voteValue()

          @$('.range').slider('value', value) if value?

  observeVoteValueChange: ->
    @autorun (computation) =>
      # Register a dependency.
      voteValue = @voteValueChange()

      return if computation.firstRun

      return unless @_voteValueChangeByUser

      Tracker.nonreactive =>
        Meteor.call 'Motion.vote',
          value: voteValue
          motion:
            _id: @currentMotionId()
        ,
          (error, result) =>
            if error
              console.error "Vote error", error
              alert "Vote error: #{error.reason or error}"
              return

  voteValueChangeByUser: (value) ->
    @voteValueChange value

    @_voteValueChangeByUser = true
    Tracker.afterFlush =>
      @_voteValueChangeByUser = false

  deselectRange: ->
    @rangeDeselected 'deselected'

  selectRange: ->
    @rangeDeselected null

  events: ->
    super.concat
      'slidechange .range, click .range': @onRangeInteraction
      'change [name="other-vote"], click [name="other-vote"]': @onRadioInteraction
      'click .oppose-vote': @onOpposeVote
      'click .support-vote': @onSupportVote
      'click .neutral-vote': @onNeutralVote

  onRangeInteraction: (event) ->
    @selectRange()

    @$('[name="other-vote"]').prop('checked', false)

    @voteValueChangeByUser parseFloat(@$('.range').slider('value'))

  onRadioInteraction: (event) ->
    @deselectRange()

    @voteValueChangeByUser @$('[name="other-vote"]:checked').val()

  onOpposeVote: (event) ->
    @$('.range').slider('value', -1.0)

  onSupportVote: (event) ->
    @$('.range').slider('value', 1.0)

  onNeutralVote: (event) ->
    @$('.range').slider('value', 0)

  currentVote: ->
    Vote.documents.findOne
      'motion._id': @currentMotionId()
    ,
      fields:
        value: 1

  abstainChecked: ->
    return unless @subscriptionsReady()

    vote = @currentVote()

    'checked' if vote?.value is Vote.VALUE.ABSTAIN

  defaultChecked: ->
    return unless @subscriptionsReady()

    vote = @currentVote()

    # This is default.
    return 'checked' unless vote?.value?

    'checked' if vote.value is Vote.VALUE.DEFAULT

  voteValue: ->
    return unless @subscriptionsReady()

    vote = @currentVote()

    if _.isNumber(vote?.value) and -1 <= vote.value <= 1
      vote.value
    else
      null
