class Discussion.CloseComponent extends Discussion.OneComponent
  @register 'Discussion.CloseComponent'

  mixins: ->
    super.concat share.ExpandableMixin

  expandableEventData: ->
    data = @discussion()

    _id: data._id
    _type: data.constructor.Meta._name

class Discussion.CloseFormComponent extends UIComponent
  @register 'Discussion.CloseFormComponent'

  STATUS: ->
    Discussion.STATUS

  canBeClosed: ->
    # All motions should have voting closed or motions should be withdrawn.
    @data()?.status is Discussion.STATUS.OPEN

  onSubmit: (event) ->
    event.preventDefault()

    discussionId = @data()._id

    passingMotions = @$('[name="passingMotions"]:checked').map((i, el) =>
      $(el).val()
    ).get()

    Meteor.call 'Discussion.close', discussionId, passingMotions, @$('[name="closingNote"]').val(), (error, result) =>
      if error
        console.error "Closing discussion error", error
        alert "Closing discussion error: #{error.reason or error}"
        return

      # TODO: Should we check the result and if it is not expected show an error instead?

      FlowRouter.go 'Discussion.display',
        _id: discussionId

class Discussion.CloseFormRowsComponent extends UIComponent
  @register 'Discussion.CloseFormRowsComponent'

  onCreated: ->
    super

    @autorun (computation) =>
      discussionId = @data()?._id
      @subscribe 'Motion.list', discussionId if discussionId

  motions: ->
    Motion.documents.find
      'discussion._id': @data()?._id
    ,
      sort:
        # The newest first.
        createdAt: -1

FlowRouter.route '/discussion/close/:_id',
  name: 'Discussion.close'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Discussion.CloseComponent'

    # We set PageTitle after we get discussion title.
