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

    console.log @$('[name="category"]').val()

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

  categories: ->
    for category, value of Point.CATEGORY
      category: value
      # TODO: Make translatable.
      label: value
