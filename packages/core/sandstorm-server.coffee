if __meteor_runtime_config__.SANDSTORM
  # Override the publish function so that we can get the current connection.
  publishCurrentContext = new Meteor.EnvironmentVariable()

  originalPublish = Meteor.publish
  Meteor.publish = (name, func) ->
    originalPublish name, (args...) ->
      publishCurrentContext.withValue {connection: @connection}, =>
        func.apply @, args

  getConnection = ->
    currentInvocation = DDP._CurrentInvocation.get()

    return currentInvocation.connection if currentInvocation

    currentContext = publishCurrentContext.get()

    return currentContext.connection if currentContext

    return null

  # Meteor.absoluteUrl doesn't work in Sandstorm, since every session has a different URL
  # whereas Meteor computes absoluteUrl based on the ROOT_URL environment variable.
  originalAbsoluteUrl = Meteor.absoluteUrl
  originalDefaultOptions = Meteor.absoluteUrl.defaultOptions

  Meteor.absoluteUrl = (path, options) ->
    unless options?.rootUrl
      # Called inside method or publish, so we have access to headers.
      if connection = getConnection()
        # TODO: Throw an error also if x-forwarded-proto header is missing when Meteor will expose it.
        #       See: https://github.com/meteor/meteor/pull/6838
        throw new Error "'Host' header missing." unless connection.httpHeaders.host

        options ?= {}
        # TODO: Remove "http" default value when Meteor will expose x-forwarded-proto header.
        #       See: https://github.com/meteor/meteor/pull/6838
        options.rootUrl = "#{connection.httpHeaders['x-forwarded-proto'] or 'http'}://#{connection.httpHeaders.host}"

    originalAbsoluteUrl path, options

  Meteor.absoluteUrl.defaultOptions = originalDefaultOptions
