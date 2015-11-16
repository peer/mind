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
    super.concat share.UpvoteableMixin, share.ExpandableMixin, share.EditableMixin

  onCreated: ->
    super

    @canEdit = new ComputedField =>
      Roles.userIsInRole Meteor.userId(), 'moderator'

  methodPrefix: ->
    'Point'

  contentName: ->
    'point'

  onBeingEdited: ->
    @callFirstWith @, 'isExpanded', false

    Tracker.afterFlush =>
      # A bit of mangling to get cursor to focus at the end of the text.
      $textarea = @$('[name="body"]')
      body = $textarea.val()
      $textarea.focus().val('').val(body).trigger('autoresize')

  onSaveEdit: (event, onSuccess) ->
    # TODO: We cannot use required for category input with Materialize.
    #       See https://github.com/Dogfalo/materialize/issues/2187
    # TODO: Make a warning or something?
    return unless @$('[name="category"]:checked').val()

    Meteor.call 'Point.update',
      _id: @data()._id
      body: @$('[name="body"]').val()
      category: @$('[name="category"]:checked').val()
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
