class Motion extends share.BaseDocument
  # createdAt: time of document creation
  # updatedAt: time of the last change
  # lastActivity: time of the last activity on the motion
  # author:
  #   _id
  #   username
  # discussion:
  #   _id
  # body: the latest version of the body
  # bodyChanges: list (the last list item is the most recent one) of
  #   updatedAt: timestamp of the change
  #   author: author of the change
  #     _id
  #     username
  #   body
  # votingOpened: time when voting started
  # votingClosed: time when voting ended

  @Meta
    name: 'Motion'
    fields: =>
      author: @ReferenceField User, User.REFERENCE_FIELDS()
      discussion: @ReferenceField Discussion
      # $slice in the projection is not supported by Meteor, so we fetch all changes and manually read the latest entry.
      body: @GeneratedField 'self', ['bodyChanges'], (fields) ->
        [fields._id, fields.bodyChanges?[fields.bodyChanges?.length - 1]?.body or '']
      bodyChanges: [
        author: @ReferenceField User, User.REFERENCE_FIELDS()
      ]
    triggers: =>
      updatedAt: share.UpdatedAtTrigger ['bodyChanges']

  @PUBLISH_FIELDS: ->
    _id: 1
    createdAt: 1
    updatedAt: 1
    lastActivity: 1
    author: 1
    discussion: 1
    body: 1
