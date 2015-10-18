class Discussion.DisplayComponent extends UIComponent
  @register 'Discussion.DisplayComponent'

  currentDiscussionId: ->
    FlowRouter.getParam '_id'

  onCreated: ->
    @autorun (computation) =>
      @subscribe 'Discussion.one', @currentDiscussionId()

  discussion: ->
    Discussion.documents.findOne @currentDiscussionId()

  notFound: ->
    @subscriptionsReady() and not @discussion()

FlowRouter.route '/discussion/:_id',
  name: 'Discussion.display'
  action: (params, queryParams) ->
    BlazeLayout.render 'LayoutComponent',
      main: 'Discussion.DisplayComponent'
