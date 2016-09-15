# Abstract class.
class Discussion.OneComponent extends UIComponent
  mixins: ->
    super.concat share.ExpandableMixin, share.EditableMixin

  onCreated: ->
    super

    @currentDiscussionId = new ComputedField =>
      FlowRouter.getParam '_id'

    @autorun (computation) =>
      discussionId = @currentDiscussionId()
      @subscribe 'Discussion.one', discussionId if discussionId

    @autorun (computation) =>
      return unless @subscriptionsReady()

      discussion = Discussion.documents.findOne @currentDiscussionId(),
        fields:
          title: 1

      if discussion
        share.PageTitle discussion.title
      else
        share.PageTitle "Not found"

    @canEdit = new ComputedField =>
      # We display the same edit form if user can edit it, or if it is closed and user can close it, which we use as a permission for editing closed discussions, too.
      @discussion() and (User.hasPermission(User.PERMISSIONS.DISCUSSION_UPDATE) or (User.hasPermission(User.PERMISSIONS.DISCUSSION_UPDATE_OWN) and (Meteor.userId() is @discussion().author._id)) or (not @discussion().isOpen() and @discussion().isClosed() and User.hasPermission(User.PERMISSIONS.DISCUSSION_CLOSE)))

    @canClose = new ComputedField =>
      @discussion() and @discussion().isOpen() and not @discussion().isClosed() and User.hasPermission(User.PERMISSIONS.DISCUSSION_CLOSE)

    @canOnlyEdit = new ComputedField =>
      @discussion() and (User.hasPermission(User.PERMISSIONS.DISCUSSION_UPDATE) or (User.hasPermission(User.PERMISSIONS.DISCUSSION_UPDATE_OWN) and (Meteor.userId() is @discussion().author._id)))

    @canEditClosed = new ComputedField =>
      @discussion() and not @discussion().isOpen() and @discussion().isClosed() and User.hasPermission(User.PERMISSIONS.DISCUSSION_CLOSE)

  discussion: ->
    Discussion.documents.findOne @currentDiscussionId()

  notFound: ->
    @subscriptionsReady() and not @discussion()

  expandableEventData: ->
    document = @discussion()

    document:
      _id: document._id
    type: document.constructor.Meta._name

  onSaveEdit: (event, onSuccess) ->
    event.preventDefault()

    if @canOnlyEdit()
      title = @$('[name="title"]').val()
      description = @$('[name="description"]').val()
    else
      # If user does not have edit permissions, we pass values as they are.
      # The server side will not update documents anyway.
      title = @discussion().title
      description = @discussion().description

    # Similarly, if an user does not have permissions to closing data of closed discussions,
    # that part of the form will not be rendered and these values will be blank, but it does
    # not matter, because the server side will not update documents.
    passingMotions = @$('[name="passingMotions"]:checked').map((i, el) =>
      $(el).val()
    ).get()

    closingNote = @$('[name="closingNote"]').val() or ''

    Meteor.call 'Discussion.update',
      _id: @currentDiscussionId()
      title: title
      description: description
    ,
      passingMotions
    ,
      closingNote
    ,
      (error, result) =>
        if error
          console.error "Update discussion error", error
          alert "Update discussion error: #{error.reason or error}"
          return

        # TODO: Should we check the result and if it is not expected show an error instead?
        #       For this method, the result is an array [changedUpdate, changedClosing].

        onSuccess()
