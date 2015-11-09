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

  editingSubscriptions: ->
    @subscribe 'Comment.forEdit', @data()._id

  onBeingEdited: ->
    @callFirstWith @, 'isExpanded', false

    Tracker.afterFlush =>
      # TODO: Move the cursor to the end of the content.
      #@$('trix-editor').get(0).editor.setSelectedRange(-1)

  onSaveEdit: (event, onSuccess) ->
    # TODO: We cannot use required for body input with trix.
    # TODO: Make a warning or something?
    return unless @hasBody()

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

  hasBody: ->
    # We require body to have at least some text content or a figure.
    $body = $(@$('[name="body"]').val())
    $body.text() or $body.has('figure')
