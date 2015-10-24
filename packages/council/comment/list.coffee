class Comment.ListComponent extends UIComponent
  @register 'Comment.ListComponent'

  onCreated: ->
    super

    @currentDiscussionId = new ComputedField =>
      FlowRouter.getParam '_id'

    @autorun (computation) =>
      discussionId = @currentDiscussionId()
      return unless discussionId
      @subscribe 'Comment.list', discussionId

  comments: ->
    Comment.documents.find
      'discussion._id': @currentDiscussionId()

  discussionExists: ->
    Discussion.documents.exists @currentDiscussionId()

class Comment.ListItemComponent extends UIComponent
  @register 'Comment.ListItemComponent'

  mixins: ->
    super.concat share.UpvotableMixin

  methodPrefix: ->
    'Comment'
