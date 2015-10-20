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
