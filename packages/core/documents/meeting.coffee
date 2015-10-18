class Meeting extends share.BaseDocument
  # createdAt: time of document creation
  # updatedAt: time of the last change
  # lastActivity: time of the last activity in the meeting
  # author:
  #   _id
  #   username
  # startAt: time when the meeting started (or will start)
  # endAt: time when the meeting ended (or will end)
  # description: the latest version of the description
  # descriptionChanges: list (the last list item is the most recent one) of
  #   updatedAt: timestamp of the change
  #   author: author of the change
  #     _id
  #     username
  #   description

  @Meta
    name: 'Meeting'
    fields: =>
      # $slice in the projection is not supported by Meteor, so we fetch all changes and manually read the latest entry.
      description: @GeneratedField 'self', ['descriptionChanges'], (fields) ->
        [fields._id, fields.descriptionChanges?[fields.descriptionChanges?.length - 1]?.description or '']
      author: @ReferenceField User, User.REFERENCE_FIELDS()
      descriptionChanges: [
        author: @ReferenceField User, User.REFERENCE_FIELDS()
      ]
    triggers: =>
      updatedAt: share.UpdatedAtTrigger ['descriptionChanges', 'startAt', 'endAt']

  @PUBLISH_FIELDS: ->
    _id: 1
    createdAt: 1
    updatedAt: 1
    lastActivity: 1
    author: 1
    startAt: 1
    endAt: 1
    description: 1
