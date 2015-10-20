class Comment.ListComponent extends UIComponent
  @register 'Comment.ListComponent'

  onCreated: ->
    super

    @currentDiscussionId = new ComputedField =>
      FlowRouter.getParam '_id'

    @autorun (computation) =>
      @subscribe 'Comment.list', @currentDiscussionId()

  comments: ->
    Comment.documents.find
      'discussion._id': @currentDiscussionId()

class Comment.ListItemComponent extends share.UpvotableItemComponent
  @register 'Comment.ListItemComponent'

  methodPrefix: ->
    'Comment'
