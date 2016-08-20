class Activity extends share.BaseDocument
  # timestamp: time of activity
  # connection
  # user:
  #   _id
  #   username
  #   avatar
  # type: type of activity
  # level: one of "debug", "error", "admin", "user", and "public"
  # data: custom data for this activity

  @Meta
    name: 'Activity'
    collection: 'Activities'
    fields: =>
      user: @ReferenceField User, User.REFERENCE_FIELDS(), false

  @LEVEL:
    DEBUG: 'debug'
    ERROR: 'error'
    ADMIN: 'admin'
    USER: 'user'
    PUBLIC: 'public'

  @PUBLISH_FIELDS: ->
    _.extend super,
      timestamp: 1
      user: 1
      type: 1
      data: 1

if Meteor.isServer
  Activity.Meta.collection._ensureIndex
    timestamp: 1

  Activity.Meta.collection._ensureIndex
    type: 1
