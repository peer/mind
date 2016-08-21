class Discussion.DisplayComponent extends Discussion.OneComponent
  @register 'Discussion.DisplayComponent'

  mixins: ->
    super.concat share.ExpandableMixin

  expandableEventData: ->
    data = @discussion()

    _id: data._id
    _type: data.constructor.Meta._name

class Discussion.EditButton extends UIComponent
  @register 'Discussion.EditButton'

FlowRouter.route '/discussion/:_id',
  name: 'Discussion.display'
  action: (params, queryParams) ->
    BlazeLayout.render 'ColumnsLayoutComponent',
      main: 'Discussion.DisplayComponent'
      first: 'Comment.ListComponent'
      second: 'Point.ListComponent'
      third: 'Motion.ListComponent'

    # We set PageTitle after we get discussion title.
