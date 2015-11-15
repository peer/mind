class Motion extends share.BaseDocument
  # createdAt: time of document creation
  # updatedAt: time of the last change
  # lastActivity: time of the last activity on the motion
  # author:
  #   _id
  #   username
  #   avatar
  # discussion:
  #   _id
  # body: the latest version of the body
  # bodyDisplay: HTML content of the body without tags needed for editing
  # bodyAttachments: list of
  # changes: list (the last list item is the most recent one) of changes
  #   updatedAt: timestamp of the change
  #   author: author of the change
  #     _id
  #     username
  #     avatar
  #   body
  # votingOpenedBy:
  #   _id
  #   username
  #   avatar
  # votingOpenedAt: time when voting started
  # votingClosedBy:
  #   _id
  #   username
  #   avatar
  # votingClosedAt: time when voting ended
  # withdrawnBy;
  #   _id
  #   username
  #   avatar
  # withdrawnAt
  # majority: one of Motion.MAJORITY values

  @Meta
    name: 'Motion'
    fields: =>
      author: @ReferenceField User, User.REFERENCE_FIELDS()
      discussion: @ReferenceField Discussion
      # $slice in the projection is not supported by Meteor, so we fetch all changes and manually read the latest entry.
      body: @GeneratedField 'self', ['changes'], (fields) =>
        [fields._id, fields.changes?[fields.changes?.length - 1]?.body or '']
      bodyDisplay: @GeneratedField 'self', ['body'], (fields) =>
        [fields._id, fields.body and @sanitizeForDisplay.sanitizeHTML fields.body]
      bodyAttachments: [
        # TODO: Make it an array of references to StorageFile as well.
        @GeneratedField 'self', ['body'], (fields) =>
          return [fields._id, []] unless fields.body
          [fields._id, ({_id} for _id in @extractAttachments fields.body)]
      ]
      changes: [
        author: @ReferenceField User, User.REFERENCE_FIELDS()
      ]
      votingOpenedBy: @ReferenceField User, User.REFERENCE_FIELDS(), false
      votingClosedBy: @ReferenceField User, User.REFERENCE_FIELDS(), false
      withdrawnBy: @ReferenceField User, User.REFERENCE_FIELDS(), false
    triggers: =>
      updatedAt: share.UpdatedAtTrigger ['changes']

  @PUBLISH_FIELDS: ->
    _id: 1
    createdAt: 1
    updatedAt: 1
    lastActivity: 1
    author: 1
    discussion: 1
    bodyDisplay: 1
    votingOpenedBy: 1
    votingOpenedAt: 1
    votingClosedBy: 1
    votingClosedAt: 1
    withdrawnBy: 1
    withdrawnAt: 1
    majority: 1

  @MAJORITY:
    SIMPLE: 'simple'
    SUPER: 'super'

  isWithdrawn: ->
    !!(@withdrawnAt and @withdrawnBy)

  isOpen: ->
    !!(@votingOpenedAt and @votingOpenedBy and not @votingClosedAt and not @votingClosedBy and @majority and not @isWithdrawn())

  isClosed: ->
    !!(@votingOpenedAt and @votingOpenedBy and @votingClosedAt and @votingClosedBy and @majority and not @isWithdrawn())

if Meteor.isServer
  Motion.Meta.collection._ensureIndex
    createdAt: 1

  Motion.Meta.collection._ensureIndex
    updatedAt: 1

  Motion.Meta.collection._ensureIndex
    lastActivity: 1

  Motion.Meta.collection._ensureIndex
    votingOpenedAt: 1

  Motion.Meta.collection._ensureIndex
    votingClosedAt: 1
