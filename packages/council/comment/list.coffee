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

  onCreated: ->
    @canUpvote = new ComputedField =>
      Meteor.userId() and Meteor.userId() isnt @data().author._id and Meteor.userId() not in _.pluck(_.pluck(@data().upvotes or [], 'author'), '_id')

    @canRemoveUpvote = new ComputedField =>
      Meteor.userId() and Meteor.userId() isnt @data().author._id and Meteor.userId() in _.pluck(_.pluck(@data().upvotes or [], 'author'), '_id')

  events: ->
    super.concat
      'click .comment-upvote': @onUpvote
      'click .comment-remove-upvote': @onRemoveUpvote

  onUpvote: (event) ->
    event.preventDefault()

    Meteor.call 'Comment.upvote', @data()._id, (error, result) =>
      console.error "Upvote error", error if error

  onRemoveUpvote: (event) ->
    event.preventDefault()

    Meteor.call 'Comment.removeUpvote', @data()._id, (error, result) =>
      return console.error "Remove upvote error", error if error
