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
  # descriptionDisplay: HTML content of the description without tags needed for editing
  # descriptionAttachments: list of
  #   _id
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

  @Meta
    name: 'Meeting'
    fields: =>
      author: @ReferenceField User, User.REFERENCE_FIELDS()
      # $slice in the projection is not supported by Meteor, so we fetch all changes and manually read the latest entry.
      title: @GeneratedField 'self', ['changes'], (fields) =>
        [fields._id, fields.changes?[fields.changes?.length - 1]?.title or '']
      description: @GeneratedField 'self', ['changes'], (fields) =>
        [fields._id, fields.changes?[fields.changes?.length - 1]?.description or '']
      descriptionDisplay: @GeneratedField 'self', ['description'], (fields) =>
        [fields._id, fields.description and @sanitizeForDisplay.sanitizeHTML fields.description]
      descriptionAttachments: [
        # TODO: Make it an array of references to StorageFile as well.
        @GeneratedField 'self', ['description'], (fields) =>
          return [fields._id, []] unless fields.description
          [fields._id, ({_id} for _id in @extractAttachments fields.description)]
      ]
      changes: [
        author: @ReferenceField User, User.REFERENCE_FIELDS()
      ]
    triggers: =>
      updatedAt: share.UpdatedAtTrigger ['changes']

  @PUBLISH_FIELDS: ->
    _id: 1
    createdAt: 1
    updatedAt: 1
    lastActivity: 1
    author: 1
    title: 1
    startAt: 1
    endAt: 1
    descriptionDisplay: 1

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
