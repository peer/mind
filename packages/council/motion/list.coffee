class Motion.ListComponent extends UIComponent
  @register 'Motion.ListComponent'

  onCreated: ->
    super

    @currentDiscussionId = new ComputedField =>
      FlowRouter.getParam '_id'

    @autorun (computation) =>
      discussionId = @currentDiscussionId()
      @subscribe 'Motion.list', discussionId if discussionId

  motions: ->
    Motion.documents.find
      'discussion._id': @currentDiscussionId()

  discussionExists: ->
    Discussion.documents.exists @currentDiscussionId()

class Motion.ListItemComponent extends UIComponent
  @register 'Motion.ListItemComponent'

  mixins: ->
    super.concat share.ExpandableMixin, share.EditableMixin

  onCreated: ->
    super

    @autorun (computation) =>
      @subscribe 'Motion.latestTally', @data()._id if @data()?._id

    @isWithdrawn = new ComputedField =>
      data = @data()
      data and data.withdrawnAt and data.withdrawnBy

    @isOpen = new ComputedField =>
      data = @data()
      data and data.votingOpenedAt and data.votingOpenedBy and not data.votingClosedAt and not data.votingClosedBy and not @isWithdrawn()

    @isClosed = new ComputedField =>
      data = @data()
      data and data.votingOpenedAt and data.votingOpenedBy and data.votingClosedAt and data.votingClosedBy and not @isWithdrawn()

    @canOpen = new ComputedField =>
      # TODO: We should also allow moderators to open motions.
      Meteor.userId() and @data() and Meteor.userId() is @data().author._id and not (@isOpen() or @isClosed() or @isWithdrawn())

    @canClose = new ComputedField =>
      # TODO: We should also allow moderators to close motions.
      Meteor.userId() and @data() and Meteor.userId() is @data().author._id and @isOpen() and not @isWithdrawn()

    @canVote = new ComputedField =>
      !!Meteor.userId()

    @canEdit = new ComputedField =>
      # TODO: We should also allow moderators to edit motions.
      @canOpen()

    @canWithdraw = new ComputedField =>
      # TODO: We should also allow moderators to withdraw motions.
      @canEdit()

  methodPrefix: ->
    'Motion'

  onBeingEdited: ->
    @callFirstWith @, 'isExpanded', false

    Tracker.afterFlush =>
      # A bit of mangling to get cursor to focus at the end of the text.
      $textarea = @$('[name="body"]')
      body = $textarea.val()
      $textarea.focus().val('').val(body).trigger('autoresize')

  events: ->
    super.concat
      'click .open-voting': @onOpenVoting
      'click .close-voting': @onCloseVoting
      'click .withdraw-motion': @onWithdrawMotion

  onOpenVoting: (event) ->
    event.preventDefault()

    Meteor.call 'Motion.openVoting', @data()._id, (error, result) =>
      if error
        console.error "Open voting error", error
        alert "Open voting error: #{error.reason or error}"
        return

  onCloseVoting: (event) ->
    event.preventDefault()

    Meteor.call 'Motion.closeVoting', @data()._id, (error, result) =>
      if error
        console.error "Close voting error", error
        alert "Close voting error: #{error.reason or error}"
        return

  onWithdrawMotion: (event) ->
    event.preventDefault()

    Meteor.call 'Motion.withdrawVoting', @data()._id, (error, result) =>
      if error
        console.error "Motion withdraw error", error
        alert "Motion withdraw error: #{error.reason or error}"
        return

  onSaveEdit: (event, onSuccess) ->
    Meteor.call 'Motion.update',
      _id: @data()._id
      body: @$('[name="body"]').val()
    ,
      (error, result) =>
        if error
          console.error "Update motion error", error
          alert "Update motion error: #{error.reason or error}"
          return

        onSuccess()

  motionPassed: ->
    tally = Tally.documents.findOne
      'motion._id': @data()._id
    ,
      sort:
        # The latest tally document.
        createdAt: -1
      fields:
        result: 1
        confidenceLevel: 1

    tally?.result > 0 && tally?.confidenceLevel >= 0.90

class Motion.TallyComponent extends UIComponent
  @register 'Motion.TallyComponent'

  onCreated: ->
    super

    @autorun (computation) =>
      @subscribe 'Motion.latestTally', @data()._id if @data()?._id

  tallyExists: ->
    Tally.documents.exists
      'motion._id': @data()._id

class Motion.TallyChartComponent extends UIComponent
  @register 'Motion.TallyChartComponent'

  onCreated: ->
    super

    @autorun (computation) =>
      @subscribe 'Motion.tally', @data()._id if @data()?._id

    @currentPointId = new ReactiveField null

    @autorun (computation) =>
      unless @isRendered() and @subscriptionsReady()
        @chart?.detach()
        @chart = null
      else
        data =
          series: [
            Tally.documents.find(
              'motion._id': @data()._id
            ,
              sort:
                createdAt: 1
            ).map (tally, index, cursor) =>
              x: tally.createdAt.valueOf()
              y: tally.result
              meta: tally._id
          ]

        if @chart
          @chart.update data

        else
          options =
            fullWidth: true
            chartPadding:
              top: 10
              right: 5
              bottom: 10
              left: 0
            axisX:
              type: Chartist.AutoScaleAxis
              onlyInteger: true
              showLabel: false
              showGrid: false
              offset: 0
            axisY:
              type: Chartist.FixedScaleAxis
              high: 1
              low: -1
              ticks: [-1, 0, 1]
              offset: 15
              labelOffset:
                x: 5
                y: 5

          @chart = new Chartist.Line @$('.tally-chart').get(0), data, options

  onDestroyed: ->
    @chart?.detach()
    @chart = null

  events: ->
    super.concat
      'mousemove .tally-chart': @onMousemove
      'mouseleave .tally-chart': @onMouseleave

  # We want to find the closest point (tally) to mouse location and set the reactive variable
  # to display its details and display or move crosshair to match the closest point.
  onMousemove: (event) ->
    mouseX = event.pageX

    $points = @$('.tally-chart .ct-point')

    unless $points.length
      @currentPointId null
      return

    pointsX = for point in $points
      $(point).offset().left

    closestPointIndex = 0
    for point, i in pointsX when Math.abs(mouseX - point) < Math.abs(mouseX - pointsX[closestPointIndex])
      closestPointIndex = i

    $closestPoint = $points.eq(closestPointIndex)

    closestPointId = $closestPoint.attr('ct:meta')

    return if @currentPointId() is closestPointId

    @currentPointId closestPointId

    closestPointX = $closestPoint.attr('x1')

    @removeCrosshair()
    @drawCrosshair closestPointX

  removeCrosshair: ->
    @chart?.svg.querySelector('.ct-crosshair')?.remove()

  drawCrosshair: (x) ->
    linesY = for line in @$('.tally-chart .ct-grid.ct-vertical')
      $(line).attr('y1')
    linesY.sort()

    @chart?.svg.querySelector('.ct-grids').elem('line',
      x1: x
      x2: x
      y1: linesY[0]
      y2: linesY[linesY.length - 1]
    , 'ct-crosshair')

  onMouseleave: (event) ->
    @currentPointId null
    @removeCrosshair()

  tally: ->
    if currentPointId = @currentPointId()
      Tally.documents.findOne currentPointId
    else
      Tally.documents.findOne
        'motion._id': @data()._id
      ,
        sort:
          # The latest tally document.
          createdAt: -1

  round: (value) ->
    value?.toFixed 2
