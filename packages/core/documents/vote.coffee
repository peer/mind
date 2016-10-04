class Vote extends share.BaseDocument
  # createdAt: time of document creation
  # updatedAt: time of the last change
  # author:
  #   _id
  #   username
  #   avatar
  # motion:
  #   _id
  #   discussion
  #     _id
  # value: the latest version of the value (can be of arbitrary type)
  # changes: list (the last list item is the most recent one) of changes
  #   updatedAt: timestamp of the change
  #   value

  @Meta
    name: 'Vote'
    fields: =>
      author: @ReferenceField User, User.REFERENCE_FIELDS(), false
      # We care only about discussion ID and not any other fields (like status).
      # We need discussion ID to be able to get all votes for a discussion.
      motion: @ReferenceField Motion, ['discussion._id']
    generators: =>
      # $slice in the projection is not supported by Meteor, so we fetch all changes and manually read the latest entry.
      value: @GeneratedField 'self', ['changes'], (fields) ->
        lastChange = fields.changes?[fields.changes?.length - 1]
        return [] unless lastChange and 'value' of lastChange
        [fields._id, lastChange.value ? Vote.VALUE.DEFAULT]
    triggers: =>
      updatedAt: share.UpdatedAtTrigger ['changes'], true
      # In motion, we care only about its ID and not any other fields (like discussion).
      # Otherwise tallying is triggered again unnecessarily.
      computeTally: @Trigger ['motion._id', 'changes'], (document, oldDocument) =>
        # Motion reference for votes should not really be changing. But we still compute a new tally for both old and
        # new motion reference, if a motion reference changed.  But if a motion document is in process of being removed,
        # we do not want to do anything for that document. Anyway, this should be rerun mostly only if changes changed,
        # so if a vote was created or changed.
        for motionId in _.uniq([document?.motion?._id, oldDocument?.motion?._id]) when motionId and Motion.documents.exists motionId
          new ComputeTallyJob(motion: _id: motionId).enqueue
            skipIfExisting: true

  # Vote should be published only to its author.
  @PUBLISH_FIELDS: ->
    _.extend super,
      _id: 1
      createdAt: 1
      updatedAt: 1
      author: 1
      motion: 1
      value: 1

  @VALUE: VotingEngine.VALUE

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
