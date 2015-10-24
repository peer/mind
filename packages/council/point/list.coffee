class Point.ListComponent extends UIComponent
  @register 'Point.ListComponent'

  onCreated: ->
    super

    @currentDiscussionId = new ComputedField =>
      FlowRouter.getParam '_id'

    @autorun (computation) =>
      discussionId = @currentDiscussionId()
      return unless discussionId
      @subscribe 'Point.list', discussionId

  inFavorPoints: ->
    Point.documents.find
      'discussion._id': @currentDiscussionId()
      category: Point.CATEGORY.IN_FAVOR

  againstPoints: ->
    Point.documents.find
      'discussion._id': @currentDiscussionId()
      category: Point.CATEGORY.AGAINST

  otherPoints: ->
    Point.documents.find
      'discussion._id': @currentDiscussionId()
      category: Point.CATEGORY.OTHER

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
    super.concat share.UpvotableMixin, share.ExpandableMixin

  onCreated: ->
    super

    @canEdit = new ComputedField =>
      # TODO: We should also allow moderators to edit points.
      Meteor.userId() and @data() and Meteor.userId() is @data().author._id

    @isBeingEdited = new ReactiveField false

    @autorun (computation) =>
      return unless @isBeingEdited()

      Tracker.afterFlush =>
        # A bit of mangling to get cursor to focus at the end of the text.
        $textarea = @$('[name="body"]')
        body = $textarea.val()
        $textarea.focus().val('').val(body).trigger('autoresize')

  methodPrefix: ->
    'Point'

  events: ->
    super.concat
      'click .edit-point': @onEditPoint
      'submit .point-edit': @onPointEditSave
      'click .point-edit-cancel': @onPointEditCancel

  onEditPoint: (event) ->
    event.preventDefault()

    @isBeingEdited true

  categories: ->
    for category, value of Point.CATEGORY
      category: value
      # TODO: Make translatable.
      label: _.capitalize category.replace('_', ' ')

  categoryColumns: ->
    "s#{Math.floor(12 / _.size(Point.CATEGORY))}"

  categoryChecked: ->
    'checked' if @currentData().category is @data().category

  onPointEditSave: (event) ->
    event.preventDefault()

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

        @isBeingEdited false

  onPointEditCancel: (event) ->
    event.preventDefault()

    @isBeingEdited false
