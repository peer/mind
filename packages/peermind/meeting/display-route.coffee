FlowRouter.route '/meeting/:_id',
  name: 'Meeting.display'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Meeting.DisplayComponent'

    # We set PageTitle after we get meeting title.
