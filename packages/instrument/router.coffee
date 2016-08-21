{routeObject} = require './lib.coffee'

FlowRouter.triggers.enter (context, redirect, stop) ->
  Meteor.apply 'Activity.route', [routeObject(context)], {noRetry: true}, (error, result) ->
    # We are ignoring errors.
