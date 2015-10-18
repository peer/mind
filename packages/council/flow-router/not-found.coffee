class NotFoundComponent extends BlazeComponent
  @register 'NotFoundComponent'

FlowRouter.notFound =
  action: ->
    BlazeLayout.render 'LayoutComponent',
      main: 'NotFoundComponent'
