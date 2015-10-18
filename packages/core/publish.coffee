# Override the publish function so that we can get the current userId.
publishCurrentContext = new Meteor.EnvironmentVariable()

originalPublish = Meteor.publish
Meteor.publish = (name, func) ->
  originalPublish name, (args...) ->
    publishCurrentContext.withValue {userId: @userId}, =>
      func.apply @, args

Meteor.userId = ->
  currentInvocation = DDP._CurrentInvocation.get()

  return currentInvocation.userId if currentInvocation

  currentContext = publishCurrentContext.get()

  return currentContext.userId if currentContext

  throw new Error "Meteor.userId() not invoked from a method or publish function."
