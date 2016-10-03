class Activity extends share.BaseDocument
  # timestamp: time of activity
  # connection
  # byUser:
  #   _id
  #   username
  #   avatar
  # forUsers: list of:
  #   _id
  #   username
  #   avatar
  # type: type of activity
  # level: one of Activity.LEVEL values
  # data: custom data for this activity

  @Meta
    name: 'Activity'
    collection: 'Activities'
    fields: =>
      byUser: @ReferenceField User, User.REFERENCE_FIELDS(), false
      forUsers: [
        @ReferenceField User, User.REFERENCE_FIELDS()
      ]
      data:
        comment: @ReferenceField Comment, [], false
        motion: @ReferenceField Motion, [], false
        point: @ReferenceField Point, [], false
        meeting: @ReferenceField Meeting, ['title'], false
        discussion: @ReferenceField Discussion, ['title'], false

  @LEVEL:
    DEBUG: 'debug'
    ERROR: 'error'
    ADMIN: 'admin'
    USER: 'user'
    GENERAL: 'general'

  @PUBLISH_FIELDS: ->
    _.extend super,
      timestamp: 1
      byUser: 1
      type: 1
      data: 1

if Meteor.isServer
  Activity.Meta.collection._ensureIndex
    timestamp: 1

  Activity.Meta.collection._ensureIndex
    type: 1
