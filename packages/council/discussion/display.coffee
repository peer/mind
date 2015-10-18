class Discussion.DisplayComponent extends UIComponent
  @register 'Discussion.DisplayComponent'

  currentDiscussionId: ->
    FlowRouter.getParam '_id'

  onCreated: ->
    super

    @autorun (computation) =>
      @subscribe 'Discussion.one', @currentDiscussionId()

  discussion: ->
    Discussion.documents.findOne @currentDiscussionId()

  notFound: ->
    @subscriptionsReady() and not @discussion()

FlowRouter.route '/discussion/:_id',
  name: 'Discussion.display'
  action: (params, queryParams) ->
    BlazeLayout.render 'ColumnsLayoutComponent',
      main: 'Discussion.DisplayComponent'
      first: 'Comment.ListComponent'
      second: 'Point.ListComponent'
