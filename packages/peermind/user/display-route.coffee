FlowRouter.route '/user/:_id',
  name: 'User.display'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'User.DisplayComponent'

    # We set PageTitle after we get user username.
