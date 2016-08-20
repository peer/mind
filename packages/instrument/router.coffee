{routeObject} = require './lib.coffee'

FlowRouter.triggers.enter (context, redirect, stop) ->
  Meteor.call 'Activity.route', routeObject(context), (error, result) ->
    # We are ignoring errors.
