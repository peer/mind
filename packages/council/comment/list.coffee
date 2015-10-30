class Comment.ListComponent extends UIComponent
  @register 'Comment.ListComponent'

  onCreated: ->
    super

    @currentDiscussionId = new ComputedField =>
      FlowRouter.getParam '_id'

    @autorun (computation) =>
      discussionId = @currentDiscussionId()
      @subscribe 'Comment.list', discussionId if discussionId

  comments: ->
    Comment.documents.find
      'discussion._id': @currentDiscussionId()
    ,
      sort:
        # The oldest first.
        createdAt: 1

  discussionExists: ->
    Discussion.documents.exists @currentDiscussionId()

class Comment.ListItemComponent extends UIComponent
  @register 'Comment.ListItemComponent'

  mixins: ->
    super.concat share.UpvoteableMixin, share.ExpandableMixin, share.EditableMixin

  onCreated: ->
    super

    @canEdit = new ComputedField =>
      # TODO: Should we also allow moderators to edit comments?
      Meteor.userId() and @data() and Meteor.userId() is @data().author._id

  methodPrefix: ->
    'Comment'

  onBeingEdited: ->
    @callFirstWith @, 'isExpanded', false

    Tracker.afterFlush =>
      # A bit of mangling to get cursor to focus at the end of the text.
      $textarea = @$('[name="body"]')
      body = $textarea.val()
      $textarea.focus().val('').val(body).trigger('autoresize')

  onSaveEdit: (event, onSuccess) ->
    Meteor.call 'Comment.update',
      _id: @data()._id
      body: @$('[name="body"]').val()
    ,
      (error, result) =>
        if error
          console.error "Update comment error", error
          alert "Update comment error: #{error.reason or error}"
          return

        onSuccess()
