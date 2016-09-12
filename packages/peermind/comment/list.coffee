class Comment.ListComponent extends UIComponent
  @register 'Comment.ListComponent'

  @displayTab: ->
    "Comments"

  onCreated: ->
    super

    @currentDiscussionId = new ComputedField =>
      FlowRouter.getParam '_id'

    @discussionIsOpen = new ComputedField =>
      Discussion.documents.findOne(@currentDiscussionId())?.isOpen()

    @discussionIsClosed = new ComputedField =>
      Discussion.documents.findOne(@currentDiscussionId())?.isClosed()

    @canClose = new ComputedField =>
      @discussion() and @discussion().isOpen() and not @discussion().isClosed() and User.hasPermission(User.PERMISSIONS.DISCUSSION_CLOSE)

    @autorun (computation) =>
      discussionId = @currentDiscussionId()
      @subscribe 'Discussion.one', discussionId if discussionId

    @autorun (computation) =>
      discussionId = @currentDiscussionId()
      @subscribe 'Comment.list', discussionId if discussionId

    @autorun (computation) =>
      return unless @subscriptionsReady()

      discussion = Discussion.documents.findOne @currentDiscussionId(),
        fields:
          title: 1

      if discussion
        share.PageTitle discussion.title
      else
        share.PageTitle "Not found"

  onRendered: ->
    super

    footerComponent = @constructor.getComponent 'FooterComponent'

    @autorun (computation) =>
      if @canClose()
        footerComponent.setFixedButton 'Discussion.DisplayComponent.FixedButton'
      else
        footerComponent.setFixedButton null

    @autorun (computation) =>
      footerComponent.fixedButtonDataContext @discussion()

  onDestroyed: ->
    super

    footerComponent = @constructor.getComponent 'FooterComponent'
    footerComponent.removeFixedButton()

  discussion: ->
    Discussion.documents.findOne @currentDiscussionId()

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
    _.every(component.hasContent() for component in @descendantComponents 'EditorComponent')

  expandableEventData: ->
    data = @data()

    _id: data._id
    _type: data.constructor.Meta._name

  discussionIsOpen: ->
    @ancestorComponent(Comment.ListComponent)?.discussionIsOpen()

  discussionIsClosed: ->
    @ancestorComponent(Comment.ListComponent)?.discussionIsClosed()

  upvotingDisabled: ->
    # TODO: We disable upvoting once discussion is closed even if we allow users to still post comments. Could we do something else?
    not (@discussionIsOpen() and not @discussionIsClosed())
