class Motion.VoteComponent extends UIComponent
  @register 'Motion.VoteComponent'

  onCreated: ->
    super

    @rangeDeselected = new ReactiveField 'deselected'

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

  onRadioInteraction: (event) ->
    @deselectRange()

  onOpposeVote: (event) ->
    @$('[name="vote"]').val(-1)

  onSupportVote: (event) ->
    @$('[name="vote"]').val(1)
