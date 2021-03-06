class Meeting extends share.BaseDocument
  # createdAt: time of document creation
  # updatedAt: time of the last change
  # lastActivity: time of the last activity in the meeting
  # author:
  #   _id
  #   username
  #   avatar
  # title: the latest version of the title
  # startAt: time when the meeting started (or will start)
  # endAt: time when the meeting ended (or will end)
  # description: the latest version of the description
  # descriptionAttachments: list of
  #   _id
  # descriptionMentions: list of
  #   _id
  # discussions: list of
  #   discussion:
  #     _id
  #   order: floating number of order
  #   time: allocated time in minutes
  # changes: list (the last list item is the most recent one) of changes
  #   updatedAt: timestamp of the change
  #   author: author of the change
  #     _id
  #     username
  #     avatar
  #   title
  #   startAt
  #   endAt
  #   description
  #   discussions: list of
  #     discussion:
  #       _id
  #     order
  #     time

  @Meta
    name: 'Meeting'
    fields: =>
      author: @ReferenceField User, User.REFERENCE_FIELDS()
      discussions: [
        discussion: @ReferenceField Discussion, [], true, 'meetings', ['title', 'startAt', 'endAt']
      ]
      changes: [
        author: @ReferenceField User, User.REFERENCE_FIELDS(), false
        # TODO: PeerDB does not support reference fields inside a nested array.
        #discussions: [
        #  discussion: @ReferenceField Discussion, [], false
        #]
      ]
      descriptionAttachments: [
        @ReferenceField StorageFile
      ]
      descriptionMentions: [
        @ReferenceField User
      ]
    generators: =>
      # $slice in the projection is not supported by Meteor, so we fetch all changes and manually read the latest entry.
      title: @GeneratedField 'self', ['changes'], (fields) =>
        lastChange = fields.changes?[fields.changes?.length - 1]
        return [] unless lastChange and 'title' of lastChange
        [fields._id, lastChange.title or '']
      startAt: @GeneratedField 'self', ['changes'], (fields) =>
        lastChange = fields.changes?[fields.changes?.length - 1]
        return [] unless lastChange and 'startAt' of lastChange
        [fields._id, lastChange.startAt or null]
      endAt: @GeneratedField 'self', ['changes'], (fields) =>
        lastChange = fields.changes?[fields.changes?.length - 1]
        return [] unless lastChange and 'endAt' of lastChange
        [fields._id, lastChange.endAt or null]
      description: @GeneratedField 'self', ['changes'], (fields) =>
        lastChange = fields.changes?[fields.changes?.length - 1]
        return [] unless lastChange and 'description' of lastChange
        [fields._id, lastChange.description or '']
      discussions: [
        @GeneratedField 'self', ['changes'], (fields) =>
          lastChange = fields.changes?[fields.changes?.length - 1]
          return [] unless lastChange and 'discussions' of lastChange
          [fields._id, lastChange.discussions or []]
      ]
      descriptionAttachments: [
        @GeneratedField 'self', ['description'], (fields) =>
          return [fields._id, []] unless fields.description
          [fields._id, ({_id} for _id in @extractAttachments fields.description)]
      ]
      descriptionMentions: [
        @GeneratedField 'self', ['body'], (fields) =>
          return [fields._id, []] unless fields.body
          [fields._id, ({_id} for _id in @extractMentions fields.body)]
      ]
    triggers: =>
      updatedAt: share.UpdatedAtTrigger ['changes']

  @PUBLISH_FIELDS: ->
    _.extend super,
      _id: 1
      createdAt: 1
      updatedAt: 1
      lastActivity: 1
      author: 1
      title: 1
      startAt: 1
      endAt: 1
      description: 1
      discussions: 1

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
