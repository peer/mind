class Vote extends share.BaseDocument
  # createdAt: time of document creation
  # updatedAt: time of the last change
  # author:
  #   _id
  #   username
  # motion:
  #   _id
  #   discussion
  # value: the latest version of the value (can be of arbitrary type)
  # changes: list (the last list item is the most recent one) of changes
  #   updatedAt: timestamp of the change
  #   value

  @Meta
    name: 'Vote'
    fields: =>
      author: @ReferenceField User, User.REFERENCE_FIELDS()
      motion: @ReferenceField Motion, ['discussion']
      # $slice in the projection is not supported by Meteor, so we fetch all changes and manually read the latest entry.
      value: @GeneratedField 'self', ['changes'], (fields) ->
        [fields._id, fields.changes?[fields.changes?.length - 1]?.value ? Vote.VALUE.DEFAULT]
    triggers: =>
      updatedAt: share.UpdatedAtTrigger ['changes'], true
      computeTally: @Trigger ['motion', 'changes'], (document, oldDocument) ->
        for motionId in _.uniq([document?.motion?._id, oldDocument?.motion?._id]) when motionId
          new ComputeTallyJob(motion: _id: motionId).enqueue
            skipIfExisting: true

  @VALUE: VotingEngine.VALUE

  # Vote should be published only to its author.
  @PUBLISH_FIELDS: ->
    _id: 1
    createdAt: 1
    updatedAt: 1
    author: 1
    motion: 1
    value: 1

if Meteor.isServer
  Vote.Meta.collection._ensureIndex
    createdAt: 1

  Vote.Meta.collection._ensureIndex
    updatedAt: 1

  # Much of our code assumes that there will be at most one document for each author per motion.
  Vote.Meta.collection._ensureIndex
    'author._id': 1
    'motion._id': 1
  ,
    unique: true

