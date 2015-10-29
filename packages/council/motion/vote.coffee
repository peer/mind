class Motion.VoteComponent extends UIComponent
  @register 'Motion.VoteComponent'

  onCreated: ->
    super

    @rangeDeselected = new ReactiveField 'deselected'

    @currentMotionId = new ComputedField =>
      @data()?._id

    @autorun (computation) =>
      motionId = @currentMotionId()
      @subscribe 'Motion.vote', motionId if motionId

    # We store current vote value into a reactive field so that we deduplicate events for the same change.
    @voteValueChange = new ReactiveField null

    @autorun (computation) =>
      # Register a dependency.
      voteValue = @voteValueChange()

      return if computation.firstRun

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

  deselectRange: ->
    @rangeDeselected 'deselected'

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

    @voteValueChange parseFloat(@$('[name="vote"]').val())

  onRadioInteraction: (event) ->
    @deselectRange()

    @voteValueChange @$('[name="other-vote"]:checked').val()

  onOpposeVote: (event) ->
    @$('[name="vote"]').val(-1)

  onSupportVote: (event) ->
    @$('[name="vote"]').val(1)

  abstainChecked: ->
    return unless @subscriptionsReady()

    vote = Vote.documents.findOne
      'motion._id': @currentMotionId()
    ,
      fields:
        value: 1

    'checked' if vote?.value is Vote.VALUE.ABSTAIN

  defaultChecked: ->
    return unless @subscriptionsReady()

    vote = Vote.documents.findOne
      'motion._id': @currentMotionId()
    ,
      fields:
        value: 1

    # This is default.
    return 'checked' unless vote?.value?

    'checked' if vote.value is Vote.VALUE.DEFAULT

  voteValue: ->
    return unless @subscriptionsReady()

    vote = Vote.documents.findOne
      'motion._id': @currentMotionId()
    ,
      fields:
        value: 1

    if _.isNumber(vote?.value) and -1 <= vote.value <= 1
      @rangeDeselected null
      value: vote.value
    else
      @rangeDeselected 'deselected'
      # We have to return the current value back, otherwise value is reset.
      value: @$('[name="vote"]').val() if @isRendered()

  VALUE: Vote.VALUE
