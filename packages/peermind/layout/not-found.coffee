class NotFoundComponent extends UIComponent
  @register 'NotFoundComponent'

FlowRouter.notFound =
  action: ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'NotFoundComponent'

    share.PageTitle "Not found"
