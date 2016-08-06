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
    @sliderDeactivated = new ReactiveField null
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
    @sliderDeactivated 'deactivated'

  selectRange: ->
    @rangeDeselected null

  events: ->
    super.concat
      # We listen to mouseup as well because otherwise if user moves the mouse over the thumb
      # after the start of the click and releases it, interaction is not detected.
      'change [name="vote"], click [name="vote"], mouseup [name="vote"]': @onRangeInteraction
      'change [name="other-vote"], click [name="other-vote"]': @onRadioInteraction
      'click .oppose-vote': @onOpposeVote
      'click .support-vote': @onSupportVote

  onRangeInteraction: (event) ->
    @selectRange()

    @$('[name="other-vote"]').prop('checked', false)

    @voteValueChangeByUser parseFloat(@$('[name="vote"]').val())

  onRadioInteraction: (event) ->
    @deselectRange()

    @voteValueChangeByUser @$('[name="other-vote"]:checked').val()

  onOpposeVote: (event) ->
    @$('[name="vote"]').slider( "option", "value", -1 );

  onSupportVote: (event) ->
    @$('[name="vote"]').slider( "option", "value", 1 );

  currentVote: ->
    Vote.documents.findOne
      'motion._id': @currentMotionId()
    ,
      fields:
        value: 1

  abstainChecked: ->
    return unless @subscriptionsReady()

    vote = @currentVote()

    return 'checked' if vote?.value is Vote.VALUE.ABSTAIN

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
      value: vote.value
    else
      # We have to return the current value back, otherwise value is reset.
      value: @$('[name="vote"]').val() if @isRendered()

  onRendered: ->
    super

    @$('[name="voteSlider"]').slider
      range: "min"
      min: -1
      max: 1
      step: 0.25
      value: 0
      animate: 300
      slide: (e, ui) ->
        $(this).parent().find(".cntr").removeClass('deactivated')
        $(this).find(".ui-slider-handle").html ui.value
        # Deselect 'abstain' and 'nothing'
        return

    @$(".ui-slider-handle").html "0"
