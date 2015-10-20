class Vote extends share.BaseDocument
  # createdAt: time of document creation
  # updatedAt: time of the last change
  # author:
  #   _id
  #   username
  # motion:
  #   _id
  # value: the latest version of the value (can be of arbitrary type)
  # valueChanges: list (the last list item is the most recent one) of
  #   updatedAt: timestamp of the change
  #   value

  @Meta
    name: 'Vote'
    fields: =>
      author: @ReferenceField User, User.REFERENCE_FIELDS()
      motion: @ReferenceField Motion, ['discussion']
      # $slice in the projection is not supported by Meteor, so we fetch all changes and manually read the latest entry.
      value: @GeneratedField 'self', ['valueChanges'], (fields) ->
        [fields._id, fields.valueChanges?[fields.valueChanges?.length - 1]?.vote or '']
    triggers: =>
      updatedAt: share.UpdatedAtTrigger ['valueChanges']

  # Vote should be published only to its author.
  @PUBLISH_FIELDS: ->
    _id: 1
    createdAt: 1
    updatedAt: 1
    author: 1
    motion: 1
    value: 1
