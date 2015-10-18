class Comment.ListComponent extends UIComponent
  @register 'Comment.ListComponent'

  parentDiscussionDisplayComponent: ->
    component = @
    while component and component not instanceof Discussion.DisplayComponent
      component = component.parentComponent()
    component

  currentDiscussionId: ->
    @parentDiscussionDisplayComponent()?.currentDiscussionId()

  onCreated: ->
    @autorun (computation) =>
      @subscribe 'Comment.list', @currentDiscussionId()

  comments: ->
    Comment.documents.find
      'discussion._id': @currentDiscussionId()

class Comment.ListItemComponent extends UIComponent
  @register 'Comment.ListItemComponent'
