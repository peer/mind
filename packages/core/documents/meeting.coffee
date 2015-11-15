class Meeting extends share.BaseDocument
  # createdAt: time of document creation
  # updatedAt: time of the last change
  # lastActivity: time of the last activity in the meeting
  # author:
  #   _id
  #   username
  #   avatar
  # startAt: time when the meeting started (or will start)
  # endAt: time when the meeting ended (or will end)
  # description: the latest version of the description
  # changes: list (the last list item is the most recent one) of changes
  #   updatedAt: timestamp of the change
  #   author: author of the change
  #     _id
  #     username
  #     avatar
  #   description

  @Meta
    name: 'Meeting'
    fields: =>
      author: @ReferenceField User, User.REFERENCE_FIELDS()
      # $slice in the projection is not supported by Meteor, so we fetch all changes and manually read the latest entry.
      description: @GeneratedField 'self', ['changes'], (fields) =>
        [fields._id, fields.changes?[fields.changes?.length - 1]?.description or '']
      changes: [
        author: @ReferenceField User, User.REFERENCE_FIELDS()
      ]
    triggers: =>
      updatedAt: share.UpdatedAtTrigger ['changes', 'startAt', 'endAt']

  @PUBLISH_FIELDS: ->
    _id: 1
    createdAt: 1
    updatedAt: 1
    lastActivity: 1
    author: 1
    startAt: 1
    endAt: 1
    description: 1

if Meteor.isServer
  Meeting.Meta.collection._ensureIndex
    createdAt: 1

  Meeting.Meta.collection._ensureIndex
    updatedAt: 1

  Meeting.Meta.collection._ensureIndex
    lastActivity: 1

  Meeting.Meta.collection._ensureIndex
    startAt: 1

  Meeting.Meta.collection._ensureIndex
    endAt: 1
