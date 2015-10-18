class Comment.ListComponent extends UIComponent
  @register 'Comment.ListComponent'

  currentDiscussionId: ->
    @ancestorComponent(Discussion.DisplayComponent)?.currentDiscussionId()

  onCreated: ->
    @autorun (computation) =>
      @subscribe 'Comment.list', @currentDiscussionId()

  comments: ->
    Comment.documents.find
      'discussion._id': @currentDiscussionId()

class Comment.ListItemComponent extends UIComponent
  @register 'Comment.ListItemComponent'
