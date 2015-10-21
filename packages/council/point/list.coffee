class Point.ListComponent extends UIComponent
  @register 'Point.ListComponent'

  onCreated: ->
    super

    @currentDiscussionId = new ComputedField =>
      FlowRouter.getParam '_id'

    @autorun (computation) =>
      discussionId = @currentDiscussionId()
      return unless discussionId
      @subscribe 'Point.list', discussionId

  inFavorPoints: ->
    Point.documents.find
      'discussion._id': @currentDiscussionId()
      category: Point.CATEGORY.IN_FAVOR

  againstPoints: ->
    Point.documents.find
      'discussion._id': @currentDiscussionId()
      category: Point.CATEGORY.AGAINST

  otherPoints: ->
    Point.documents.find
      'discussion._id': @currentDiscussionId()
      category: Point.CATEGORY.OTHER

  pointsExists: ->
    Point.documents.exists
      'discussion._id': @currentDiscussionId()
      category:
        $in: _.values Point.CATEGORY

class Point.ListItemComponent extends share.UpvotableItemComponent
  @register 'Point.ListItemComponent'

  methodPrefix: ->
    'Point'
