class Motion.ListComponent extends UIComponent
  @register 'Motion.ListComponent'

  currentDiscussionId: ->
    FlowRouter.getParam '_id'

  onCreated: ->
    super

    @autorun (computation) =>
      @subscribe 'Motion.list', @currentDiscussionId()

  motions: ->
    Motion.documents.find
      'discussion._id': @currentDiscussionId()

class Motion.ListItemComponent extends UIComponent
  @register 'Motion.ListItemComponent'

  onCreated: ->
    super

    @canOpen = new ComputedField =>
      # TODO: We should also allow moderators to open motions.
      Meteor.userId() and @data() and Meteor.userId() is @data().author._id and not @data().votingOpenedAt and not @data().votingOpenedBy and not @data().votingClosedAt and not @data().votingClosedBy

    @canClose = new ComputedField =>
      # TODO: We should also allow moderators to close motions.
      Meteor.userId() and @data() and Meteor.userId() is @data().author._id and @data().votingOpenedAt and @data().votingOpenedBy and not @data().votingClosedAt and not @data().votingClosedBy

  events: ->
    super.concat
      'click .voting-open': @onOpenVoting
      'click .voting-close': @onCloseVoting

  onOpenVoting: (event) ->
    event.preventDefault()

    Meteor.call 'Motion.openVoting', @data()._id, (error, result) =>
      console.error "Open voting error", error if error

  onCloseVoting: (event) ->
    event.preventDefault()

    Meteor.call 'Motion.closeVoting', @data()._id, (error, result) =>
      return console.error "Close voting error", error if error
