class Comment.ListComponent extends UIComponent
  @register 'Comment.ListComponent'

  currentDiscussionId: ->
    FlowRouter.getParam '_id'

  onCreated: ->
    super

    @autorun (computation) =>
      @subscribe 'Comment.list', @currentDiscussionId()

  comments: ->
    Comment.documents.find
      'discussion._id': @currentDiscussionId()

class Comment.ListItemComponent extends share.UpvotableItemComponent
  @register 'Comment.ListItemComponent'

  methodPrefix: ->
    'Comment'
