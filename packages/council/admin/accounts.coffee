class Admin.AccountsComponent extends UIComponent
  @register 'Admin.AccountsComponent'

  onCreated: ->
    super

    @autorun (computation) =>
      if @hasAccess()
        share.PageTitle "Accounts admin"
      else
        share.PageTitle "Not found"

  hasAccess: ->
    Roles.userIsInRole Meteor.userId(), 'admin'

FlowRouter.route '/admin/accounts',
  name: 'Admin.accounts'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Admin.AccountsComponent'

    # We set PageTitle based on the access.
