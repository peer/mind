class Point.ListComponent extends UIComponent
  @register 'Point.ListComponent'

  currentDiscussionId: ->
    FlowRouter.getParam '_id'

  onCreated: ->
    super

    @autorun (computation) =>
      @subscribe 'Point.list', @currentDiscussionId()

  proPoints: ->
    Point.documents.find
      'discussion._id': @currentDiscussionId()
      category: Point.CATEGORY.PRO

  contraPoints: ->
    Point.documents.find
      'discussion._id': @currentDiscussionId()
      category: Point.CATEGORY.CONTRA

  notePoints: ->
    Point.documents.find
      'discussion._id': @currentDiscussionId()
      category: Point.CATEGORY.NOTE

class Point.ListItemComponent extends share.UpvotableItemComponent
  @register 'Point.ListItemComponent'

  methodPrefix: ->
    'Point'
