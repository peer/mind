class Motion.ListComponent extends UIComponent
  @register 'Motion.ListComponent'

  onCreated: ->
    super

    @currentDiscussionId = new ComputedField =>
      FlowRouter.getParam '_id'

    @autorun (computation) =>

    @autorun (computation) =>
      discussionId = @currentDiscussionId()
      return unless discussionId
      @subscribe 'Motion.list', discussionId

  motions: ->
    Motion.documents.find
      'discussion._id': @currentDiscussionId()

  discussionExists: ->
    Discussion.documents.exists @currentDiscussionId()

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

    @isBeingEdited = new ReactiveField false

    @autorun (computation) =>
      return unless @isBeingEdited()

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
      'click .edit-motion': @onEditMotion
      'submit .motion-edit': @onMotionEditSave
      'click .motion-edit-cancel': @onMotionEditCancel

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

  onEditMotion: (event) ->
    event.preventDefault()

    @isBeingEdited true

  onMotionEditSave: (event) ->
    event.preventDefault()

    Meteor.call 'Motion.update',
      _id: @data()._id
      body: @$('[name="body"]').val()
    ,
      (error, documentId) =>
        if error
          console.error "Update motion error", error
          alert "Update motion error: #{error.reason or error}"
          return

        @isBeingEdited false

  onMotionEditCancel: (event) ->
    event.preventDefault()

    @isBeingEdited false
