class Motion.ListComponent extends UIComponent
  @register 'Motion.ListComponent'

  onCreated: ->
    super

    @currentDiscussionId = new ComputedField =>
      FlowRouter.getParam '_id'

    @autorun (computation) =>

    @autorun (computation) =>
      @subscribe 'Motion.list', @currentDiscussionId()

  motions: ->
    Motion.documents.find
      'discussion._id': @currentDiscussionId()

class Motion.ListItemComponent extends UIComponent
  @register 'Motion.ListItemComponent'

  onCreated: ->
    super

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

  events: ->
    super.concat
      'click .open-voting': @onOpenVoting
      'click .close-voting': @onCloseVoting
      'click .motion-withdraw': @onMotionWithdraw
      'click .motion-edit': @onMotionEdit

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

  onMotionWithdraw: (event) ->
    event.preventDefault()

    Meteor.call 'Motion.withdrawVoting', @data()._id, (error, result) =>
      if error
        console.error "Motion withdraw error", error
        alert "Motion withdraw error: #{error.reason or error}"
        return

  onMotionEdit: (event) ->
    event.preventDefault()

    # TODO: Implement.
