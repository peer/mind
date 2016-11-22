# TODO: Remove once this is merged in and we upgrade to that Meteor version.
#       See: https://github.com/meteor/meteor/pull/8088
# TODO: It should also be fixed on the server side, but we are not really using simulated methods there.
saveOriginals = Meteor.connection.__proto__._saveOriginals
Meteor.connection.__proto__._saveOriginals = ->
  @_flushBufferedWrites()
  saveOriginals.apply this, arguments
