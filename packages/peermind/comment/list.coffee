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
    super.concat share.ExpandableMixin, share.EditableMixin

  onCreated: ->
    super

    @canEdit = new ComputedField =>
      @data() and (User.hasPermission(User.PERMISSIONS.COMMENT_UPDATE) or (User.hasPermission(User.PERMISSIONS.COMMENT_UPDATE_OWN) and (Meteor.userId() is @data().author._id)))

  editingSubscriptions: ->
    @subscribe 'Comment.forEdit', @data()._id

  onBeingEdited: ->
    @callFirstWith @, 'isExpanded', false

    Tracker.afterFlush =>
      # TODO: Move the cursor to the end of the content.
      #@$('trix-editor').get(0).editor.setSelectedRange(-1)

  onSaveEdit: (event, onSuccess) ->
    # TODO: We cannot use required for body input with trix.
    unless @hasBody()
      # TODO: Use flash messages.
      alert "Comment is required."
      return

    Meteor.call 'Comment.update',
      _id: @data()._id
      body: @$('[name="body"]').val()
    ,
      (error, result) =>
        if error
          console.error "Update comment error", error
          alert "Update comment error: #{error.reason or error}"
          return

        # TODO: Should we check the result and if it is not expected show an error instead?

        onSuccess()

  hasBody: ->
    # TODO: Search all descendant components, not just children.
    _.every(component.hasContent() for component in @childComponents 'EditorComponent')

  expandableEventData: ->
    data = @data()

    _id: data._id
    _type: data.constructor.Meta._name
