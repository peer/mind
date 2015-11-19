class Admin.AccountsComponent extends UIComponent
  @register 'Admin.AccountsComponent'

  hasAccess: ->
    Roles.userIsInRole Meteor.userId(), 'admin'

FlowRouter.route '/admin/accounts',
  name: 'Admin.accounts'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Admin.AccountsComponent'

    share.PageTitle "Accounts admin"
