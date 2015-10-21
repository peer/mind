class Point.NewComponent extends UIComponent
  @register 'Point.NewComponent'

  onCreated: ->
    super

    @canNew = new ComputedField =>
      !!Meteor.userId()

  currentDiscussionId: ->
    @ancestorComponent(Point.ListComponent)?.currentDiscussionId()

  events: ->
    super.concat
      'submit .point-new': @onSubmit

  onSubmit: (event) ->
    event.preventDefault()

    # TODO: We cannot use required for category input with Materialize.
    #       See https://github.com/Dogfalo/materialize/issues/2187
    # TODO: Make a warning or something?
    return unless @$('[name="category"]:checked').val()

    Meteor.call 'Point.new',
      body: @$('[name="body"]').val()
      category: @$('[name="category"]:checked').val()
      discussion:
        _id: @currentDiscussionId()
    ,
      (error, documentId) =>
        if error
          console.error "New point error", error
          alert "New point error: #{error.reason or error}"
          return

        @$('[name="body"]').val('')
        @$('[name="category"]').prop('checked', false)

  categories: ->
    for category, value of Point.CATEGORY
      category: value
      # TODO: Make translatable.
      label: _.capitalize category.replace('_', ' ')

  categoryColumns: ->
    "s#{Math.floor(12 / _.size(Point.CATEGORY))}"
