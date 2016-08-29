class Point.ListComponent extends UIComponent
  @register 'Point.ListComponent'

  onCreated: ->
    super

    @currentDiscussionId = new ComputedField =>
      FlowRouter.getParam '_id'

    @autorun (computation) =>
      discussionId = @currentDiscussionId()
      @subscribe 'Point.list', discussionId if discussionId

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

  editingSubscriptions: ->
    @subscribe 'Point.forEdit', @data()._id

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
    # TODO: Search all descendant components, not just children.
    _.every(component.hasContent() for component in @childComponents 'EditorComponent')

  expandableEventData: ->
    data = @data()

    _id: data._id
    _type: data.constructor.Meta._name
