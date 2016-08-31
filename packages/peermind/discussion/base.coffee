# Abstract class.
class Discussion.OneComponent extends UIComponent
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

  discussion: ->
    Discussion.documents.findOne @currentDiscussionId()

  notFound: ->
    @subscriptionsReady() and not @discussion()
