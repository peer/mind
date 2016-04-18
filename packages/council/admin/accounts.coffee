class Admin.AccountsComponent extends UIComponent
  @register 'Admin.AccountsComponent'

  hasAccess: ->
    User.hasPermission User.PERMISSIONS.USER_ADMIN

FlowRouter.route '/admin/accounts',
  name: 'Admin.accounts'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Admin.AccountsComponent'

    share.PageTitle "Accounts admin"
