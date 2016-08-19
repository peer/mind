FlowRouter.triggers.enter (context, redirect, stop) ->
  Meteor.call 'Activity.route', context.route.name, context.params, context.queryParams, context.context.hash, context.context.canonicalPath, context.oldRoute?.name or null, (error, result) ->
    # We are ignoring errors.
