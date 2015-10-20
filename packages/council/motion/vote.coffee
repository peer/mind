class Motion.VoteComponent extends UIComponent
  @register 'Motion.VoteComponent'

  onCreated: ->
    super

    @rangeDeselected = new ReactiveField 'deselected'

    @currentMotionId = new ComputedField =>
      @data()?._id

    @autorun (computation) =>
      @subscribe 'Motion.vote', @currentMotionId()

    # We store current vote value into a reactive field so that we deduplicate events for the same change.
    @voteValue = new ReactiveField null

    @autorun (computation) =>
      # Register a dependency.
      voteValue = @voteValue()

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

    @voteValue @$('[name="vote"]').val()

  onRadioInteraction: (event) ->
    @deselectRange()

    @voteValue @$('[name="other-vote"]:checked').val()

  onOpposeVote: (event) ->
    @$('[name="vote"]').val(-1)

  onSupportVote: (event) ->
    @$('[name="vote"]').val(1)

  vote: ->
    Vote.documents.findOne
      'motion._id': @currentMotionId()
