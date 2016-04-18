if Meteor.settings?.public?.sandstorm
  # Meteor.absoluteUrl doesn't work in Sandstorm, since every session has a different URL
  # whereas Meteor computes absoluteUrl based on the ROOT_URL environment variable.
  originalAbsoluteUrl = Meteor.absoluteUrl
  originalDefaultOptions = Meteor.absoluteUrl.defaultOptions

  Meteor.absoluteUrl = (path, options) ->
    unless options?.rootUrl
      options ?= {}
      options.rootUrl = window.location.origin

    originalAbsoluteUrl path, options

  Meteor.absoluteUrl.defaultOptions = originalDefaultOptions
