STATUS_ORDER = {}
STATUS_ORDER[Motion.STATUS.DRAFT] = 0
STATUS_ORDER[Motion.STATUS.OPEN] = 1
STATUS_ORDER[Motion.STATUS.CLOSED] = 2
STATUS_ORDER[Motion.STATUS.WITHDRAWN] = 3

class Motion.ListComponent extends UIComponent
  @register 'Motion.ListComponent'

  onCreated: ->
    super

    @currentDiscussionId = new ComputedField =>
      FlowRouter.getParam '_id'

    @discussionIsOpen = new ComputedField =>
      Discussion.documents.findOne(@currentDiscussionId())?.isOpen()

    @discussionIsClosed = new ComputedField =>
      Discussion.documents.findOne(@currentDiscussionId())?.isClosed()

    @autorun (computation) =>
      discussionId = @currentDiscussionId()
      @subscribe 'Motion.list', discussionId if discussionId

  motions: ->
    Motion.documents.find
      'discussion._id': @currentDiscussionId()
    ,
      sort: (a, b) =>
        # In ascending order.
        diff = STATUS_ORDER[a.status] - STATUS_ORDER[b.status]
        return diff if diff isnt 0

        # The oldest first.
        a.createdAt.valueOf() - b.createdAt.valueOf()

  passingMotions: ->
    passingMotions = _.pluck Discussion.documents.findOne(@currentDiscussionId(), fields: passingMotions: 1)?.passingMotions or [], '_id'

    Motion.documents.find
      _id:
        $in: passingMotions
      'discussion._id': @currentDiscussionId()
    ,
      sort:
        # The oldest first.
        createdAt: 1

  otherMotions: ->
    passingMotions = _.pluck Discussion.documents.findOne(@currentDiscussionId(), fields: passingMotions: 1)?.passingMotions or [], '_id'

    Motion.documents.find
      _id:
        $nin: passingMotions
      'discussion._id': @currentDiscussionId()
    ,
      sort:
        # The oldest first.
        createdAt: 1

  discussionExists: ->
    Discussion.documents.exists @currentDiscussionId()

class Motion.ListItemComponent extends UIComponent
  @register 'Motion.ListItemComponent'

  mixins: ->
    super.concat share.ExpandableMixin, share.EditableMixin

  constructor: (kwargs) ->
    super

    _.extend @, _.pick (kwargs?.hash or {}), 'noExtraMetadataButtons'

  onCreated: ->
    super

    @autorun (computation) =>
      @subscribe 'Motion.latestTally', @data()._id if @data()?._id

    @canOpen = new ComputedField =>
      @data() and User.hasPermission(User.PERMISSIONS.MOTION_OPEN_VOTING) and not (@data().isOpen() or @data().isClosed() or @data().isWithdrawn())

    @canClose = new ComputedField =>
      @data() and User.hasPermission(User.PERMISSIONS.MOTION_CLOSE_VOTING) and @data().isOpen() and not @data().isWithdrawn()

    @canVote = new ComputedField =>
      User.hasPermission User.PERMISSIONS.MOTION_VOTE

    @canEdit = new ComputedField =>
      @data() and (User.hasPermission(User.PERMISSIONS.MOTION_UPDATE) or (User.hasPermission(User.PERMISSIONS.MOTION_UPDATE_OWN) and (Meteor.userId() is @data().author._id))) and not (@data().isOpen() or @data().isClosed() or @data().isWithdrawn())

    @canWithdraw = new ComputedField =>
      @data() and (User.hasPermission(User.PERMISSIONS.MOTION_WITHDRAW) or (User.hasPermission(User.PERMISSIONS.MOTION_WITHDRAW_OWN) and (Meteor.userId() is @data().author._id))) and not (@data().isOpen() or @data().isClosed() or @data().isWithdrawn())

    @canUpvote = new ComputedField =>
      @data() and not (@data().isOpen() or @data().isClosed() or @data().isWithdrawn())

  onBeingEdited: ->
    @callFirstWith @, 'isExpanded', false

    Tracker.afterFlush =>
      # TODO: Move the cursor to the end of the content.
      #@$('trix-editor').get(0).editor.setSelectedRange(-1)

  onSaveEdit: (event, onSuccess) ->
    # TODO: We cannot use required for body input with trix.
    unless @hasBody()
      # TODO: Use flash messages.
      alert "Motion is required."
      return

    Meteor.call 'Motion.update',
      _id: @data()._id
      body: @$('[name="body"]').val()
    ,
      (error, result) =>
        if error
          console.error "Update motion error", error
          alert "Update motion error: #{error.reason or error}"
          return

        # TODO: Should we check the result and if it is not expected show an error instead?

        onSuccess()

  hasBody: ->
    _.every(component.hasContent() for component in @descendantComponents 'EditorComponent')

  motionPassed: ->
    tally = Tally.documents.findOne
      'motion._id': @data()._id
    ,
      sort:
        # The latest tally document.
        createdAt: -1
      fields:
        result: 1
        confidence: 1

    tally?.result > 0 && tally?.confidence >= 0.90

  expandableEventData: ->
    data = @data()

    _id: data._id
    _type: data.constructor.Meta._name

  renderExtraMetadataButtons: (parentComponent, metadataComponent) ->
    return null if @noExtraMetadataButtons

    return null if not (@discussionIsOpen() and not @discussionIsClosed())

    Motion.ExtraMetadataButtonsComponent.renderComponent parentComponent

  discussionIsOpen: ->
    @ancestorComponent(Motion.ListComponent)?.discussionIsOpen()

  discussionIsClosed: ->
    @ancestorComponent(Motion.ListComponent)?.discussionIsClosed()

  upvotingDisabled: ->
    not (@discussionIsOpen() and not @discussionIsClosed())

class Motion.ExtraMetadataButtonsComponent extends UIComponent
  @register 'Motion.ExtraMetadataButtonsComponent'

  onButtonClick: (event) ->
    event.preventDefault()

    editor = $('trix-editor[input="new-motion-description"]').get(0).editor

    # Move the cursor to the end of existing content.
    originalLastPosition = editor.getDocument().getLength() - 1
    editor.setSelectedRange originalLastPosition

    # Add it at the end of existing content.
    editor.insertHTML @data().body

    # Select new content.
    editor.setSelectedRange [originalLastPosition, editor.getDocument().getLength() - 1]

class Motion.WithdrawComponent extends UIComponent
  @register 'Motion.WithdrawComponent'

  onRendered: ->
    super

    @autorun (computation) =>
      $modalTrigger = @ancestorComponent(Motion.ListItemComponent).$(".modal-trigger[data-target='motion-withdraw-dialog-#{@data()._id}']")
      return unless $modalTrigger
      computation.stop()

      $modalTrigger.leanModal()

  events: ->
    super.concat
      'click .confirm-withdraw-motion': @onWithdrawMotion

  onWithdrawMotion: (event) ->
    event.preventDefault()

    Meteor.call 'Motion.withdraw', @data()._id, (error, result) =>
      if error
        console.error "Motion withdraw error", error
        alert "Motion withdraw error: #{error.reason or error}"
        return

      # TODO: Should we check the result and if it is not expected show an error instead?

class Motion.OpenVotingComponent extends UIComponent
  @register 'Motion.OpenVotingComponent'

  onRendered: ->
    super

    @autorun (computation) =>
      $modalTrigger = @ancestorComponent(Motion.ListItemComponent).$(".modal-trigger[data-target='open-voting-dialog-#{@data()._id}']")
      return unless $modalTrigger
      computation.stop()

      $modalTrigger.leanModal()

  events: ->
    super.concat
      'click .simplemajority-open-voting': @onOpenSimpleMajority
      'click .supermajority-open-voting': @onOpenSuperMajority

  onOpenSimpleMajority: (event) ->
    event.preventDefault()

    @_openMotion Motion.MAJORITY.SIMPLE

  onOpenSuperMajority: (event) ->
    event.preventDefault()

    @_openMotion Motion.MAJORITY.SUPER

  _openMotion: (majority) ->
    Meteor.call 'Motion.openVoting', @data()._id, majority, (error, result) =>
      if error
        console.error "Open voting error", error
        alert "Open voting error: #{error.reason or error}"
        return

      # TODO: Should we check the result and if it is not expected show an error instead?

class Motion.CloseVotingComponent extends UIComponent
  @register 'Motion.CloseVotingComponent'

  onRendered: ->
    super

    @autorun (computation) =>
      $modalTrigger = @ancestorComponent(Motion.ListItemComponent).$(".modal-trigger[data-target='close-voting-dialog-#{@data()._id}']")
      return unless $modalTrigger
      computation.stop()

      $modalTrigger.leanModal()

  events: ->
    super.concat
      'click .confirm-close-voting': @onCloseVoting

  onCloseVoting: (event) ->
    event.preventDefault()

    Meteor.call 'Motion.closeVoting', @data()._id, (error, result) =>
      if error
        console.error "Close voting error", error
        alert "Close voting error: #{error.reason or error}"
        return

      # TODO: Should we check the result and if it is not expected show an error instead?

class Motion.TallyComponent extends UIComponent
  @register 'Motion.TallyComponent'

  onCreated: ->
    super

    @autorun (computation) =>
      @subscribe 'Motion.tally', @data()._id if @data()?._id

    @currentPointId = new ReactiveField null

  tallyExists: ->
    Tally.documents.exists
      'motion._id': @data()._id

  tally: ->
    return Tally.documents.findOne currentPointId if currentPointId = @currentPointId()

    Tally.documents.findOne
      'motion._id': @data()._id
    ,
      sort:
        # The latest tally document.
        createdAt: -1

  round: (value) ->
    value?.toFixed 2

  # A special version of rounding which displays 0.90 only if the value really reached 0.90. We do
  # this to prevent confusion in people. Simply rounding down would make it less precise elsewhere
  # and it would be much harder to reach 1.00 (which is maybe also good if it would be harder?)
  confidenceRound: (value) ->
    return unless value?

    rounded = value.toFixed 2

    return '0.89' if rounded is '0.90' and value < 0.90

    rounded

  displayMajority: ->
    if @data().majority is Motion.MAJORITY.SIMPLE
      "simple majority"
    else if @data().majority is Motion.MAJORITY.SUPER
      "supermajority"

class Motion.TallyChartComponent extends UIComponent
  @register 'Motion.TallyChartComponent'

  onCreated: ->
    super

    @autorun (computation) =>
      unless @isRendered() and @tallySubscriptionReady()
        @chart?.detach()
        @chart = null
      else
        series = []
        previousTally = null

        Tally.documents.find(
          'motion._id': @data()._id
        ,
          sort:
            createdAt: 1
          fields:
            createdAt: 1
            result: 1
            population: 1
            abstentions: 1
            confidence: 1
            votesCount: 1
          transform: null
        ).forEach (tally, index, cursor) =>
          # If tally is exactly the same as a previous one, we do not draw it.
          return if previousTally and EJSON.equals _.omit(previousTally, '_id', 'createdAt'), _.omit(tally, '_id', 'createdAt')
          previousTally = tally

          series.push
            x: tally.createdAt.valueOf()
            y: tally.result
            meta: tally._id

        data =
          series: [series]

        if @chart
          @chart.update data

        else if not data.series[0].length
          return

        else
          options =
            lineSmooth: Chartist.Interpolation.none()
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

  currentPointId: (args...) ->
    @callAncestorWith 'currentPointId', args...

  tallySubscriptionReady: ->
    @ancestorComponent(Motion.TallyComponent).subscriptionsReady()

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
      parseFloat $(line).attr('y1')
    linesY.sort (a, b) =>
      b - a

    @chart?.svg.querySelector('.ct-grids').elem('line',
      x1: x
      x2: x
      y1: linesY[0]
      y2: linesY[linesY.length - 1]
    , 'ct-crosshair')

  onMouseleave: (event) ->
    @currentPointId null
    @removeCrosshair()
