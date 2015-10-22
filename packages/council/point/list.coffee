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

  discussionExists: ->
    Discussion.documents.exists @currentDiscussionId()

class Point.ListItemComponent extends share.UpvotableItemComponent
  @register 'Point.ListItemComponent'

  onCreated: ->
    super

    @itemExpanded = new ReactiveField false

  methodPrefix: ->
    'Point'

  events: ->
    super.concat
      'click .expand-button': @onExpandButton

  onExpandButton: (event) ->
    event.preventDefault()

    @itemExpanded not @itemExpanded()

  insertDOMElement: (parent, node, before) ->
    $node = $(node)
    if $node.hasClass('expansion')
      super parent, node, before
      $(node).velocity 'slideDown',
        duration: 'fast'
        queue: false
    else
      super parent, node, before

  removeDOMElement: (parent, node, before) ->
    $node = $(node)
    if $node.hasClass('expansion')
      $(node).velocity 'slideUp',
        duration: 'fast'
        queue: false
        complete: (element) =>
          super parent, node, before
    else
      super parent, node, before
