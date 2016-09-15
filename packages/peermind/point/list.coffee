class Point.ListComponent extends UIComponent
  @register 'Point.ListComponent'

  @displayTab: ->
    "Points"

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
      @subscribe 'Point.list', discussionId if discussionId

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

  inFavorPoints: ->
    Point.documents.find
      'discussion._id': @currentDiscussionId()
      category: Point.CATEGORY.IN_FAVOR
    ,
      sort:
        # The oldest first.
        createdAt: 1

  againstPoints: ->
    Point.documents.find
      'discussion._id': @currentDiscussionId()
      category: Point.CATEGORY.AGAINST
    ,
      sort:
        # The oldest first.
        createdAt: 1

  otherPoints: ->
    Point.documents.find
      'discussion._id': @currentDiscussionId()
      category: Point.CATEGORY.OTHER
    ,
      sort:
        # The oldest first.
        createdAt: 1

  pointsExists: ->
    Point.documents.exists
      'discussion._id': @currentDiscussionId()
      category:
        $in: _.values Point.CATEGORY

  discussionExists: ->
    Discussion.documents.exists @currentDiscussionId()

class Point.ListItemComponent extends UIComponent
  @register 'Point.ListItemComponent'

  mixins: ->
    super.concat share.ExpandableMixin, share.EditableMixin

  onCreated: ->
    super

    @canEdit = new ComputedField =>
      @data() and (User.hasPermission(User.PERMISSIONS.POINT_UPDATE) or (User.hasPermission(User.PERMISSIONS.POINT_UPDATE_OWN) and (Meteor.userId() is @data().author._id)))

  onBeingEdited: ->
    @callFirstWith @, 'isExpanded', false

    Tracker.afterFlush =>
      # TODO: Move the cursor to the end of the content.
      #@$('trix-editor').get(0).editor.setSelectedRange(-1)

  onSaveEdit: (event, onSuccess) ->
    # TODO: We cannot use required for body input with trix.
    unless @hasBody()
      # TODO: Use flash messages.
      alert "Point is required."
      return

    category = @$('[name="category"]:checked').val()

    unless category
      # TODO: We cannot use required for radio input with Materialize.
      #       See https://github.com/Dogfalo/materialize/issues/2187
      # TODO: Use flash messages.
      alert "Category is required."
      return

    Meteor.call 'Point.update',
      _id: @data()._id
      body: @$('[name="body"]').val()
      category: category
    ,
      (error, result) =>
        if error
          console.error "Update point error", error
          alert "Update point error: #{error.reason or error}"
          return

        # TODO: Should we check the result and if it is not expected show an error instead?

        onSuccess()

  categories: ->
    for category, value of Point.CATEGORY
      category: value
      # TODO: Make translatable.
      label: _.capitalize category.replace('_', ' ')

  categoryColumns: ->
    "s#{Math.floor(12 / _.size(Point.CATEGORY))}"

  categoryChecked: ->
    'checked' if @currentData().category is @data().category

  hasBody: ->
    _.every(component.hasContent() for component in @descendantComponents 'EditorComponent')

  expandableEventData: ->
    document = @data()

    document:
      _id: document._id
    type: document.constructor.Meta._name

  discussionIsOpen: ->
    @ancestorComponent(Point.ListComponent)?.discussionIsOpen()

  discussionIsClosed: ->
    @ancestorComponent(Point.ListComponent)?.discussionIsClosed()

  upvotingDisabled: ->
    not (@discussionIsOpen() and not @discussionIsClosed())
