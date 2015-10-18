class Discussion extends share.BaseDocument
  # createdAt: time of document creation
  # updatedAt: time of the last change
  # lastActivity: time of the last activity in the discussion
  # author:
  #   _id
  #   username
  # title: the latest version of the title
  # titleChanges: list (the last list item is the most recent one) of
  #   updatedAt: timestamp of the change
  #   author: author of the change
  #     _id
  #     username
  #   title
  # description: the latest version of the description
  # descriptionChanges: list (the last list item is the most recent one) of
  #   updatedAt: timestamp of the change
  #   author: author of the change
  #     _id
  #     username
  #   description
  # meetings: list, if a discussion is associated with a meeting (or meetings)
  #   _id

  @Meta
    name: 'Discussion'
    fields: =>
      # $slice in the projection is not supported by Meteor, so we fetch all changes and manually read the latest entry.
      title: @GeneratedField 'self', ['titleChanges'], (fields) ->
        [fields._id, fields.titleChanges?[fields.titleChanges?.length - 1]?.title or '']
      description: @GeneratedField 'self', ['descriptionChanges'], (fields) ->
        [fields._id, fields.descriptionChanges?[fields.descriptionChanges?.length - 1]?.description or '']
      author: @ReferenceField User, User.REFERENCE_FIELDS()
      titleChanges: [
        author: @ReferenceField User, User.REFERENCE_FIELDS()
      ]
      descriptionChanges: [
        author: @ReferenceField User, User.REFERENCE_FIELDS()
      ]
      meetings: [@ReferenceField Meeting]
    triggers: =>
      updatedAt: share.UpdatedAtTrigger ['titleChanges', 'descriptionChanges', 'meetings']

  @PUBLISH_FIELDS: ->
    _id: 1
    createdAt: 1
    updatedAt: 1
    lastActivity: 1
    author: 1
    title: 1
    description: 1
    meetings: 1
