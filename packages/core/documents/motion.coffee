class Motion extends share.UpvotableDocument
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
  #   _id
  # changes: list (the last list item is the most recent one) of changes
  #   updatedAt: timestamp of the change
  #   author: author of the change
  #     _id
  #     username
  #     avatar
  #   body
  # upvotes: list of
  #   createdAt: timestamp of the upvote
  #   author: author of the upvote
  #     _id
  # upvotesCount
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
    fields: (fields) =>
      _.extend fields,
        votingOpenedBy: @ReferenceField User, User.REFERENCE_FIELDS(), false
        votingClosedBy: @ReferenceField User, User.REFERENCE_FIELDS(), false
        withdrawnBy: @ReferenceField User, User.REFERENCE_FIELDS(), false
        # We override this field with one with a reverse field.
        discussion: @ReferenceField Discussion, [], true, 'motions', []

  @PUBLISH_FIELDS: ->
    _.extend super,
      votingOpenedBy: 1
      votingOpenedAt: 1
      votingClosedBy: 1
      votingClosedAt: 1
      withdrawnBy: 1
      withdrawnAt: 1
      majority: 1

  @MAJORITY: VotingEngine.MAJORITY

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
