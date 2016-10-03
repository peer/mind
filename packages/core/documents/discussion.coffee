class Discussion extends share.BaseDocument
  # createdAt: time of document creation
  # updatedAt: time of the last change
  # lastActivity: time of the last activity in the discussion
  # author:
  #   _id
  #   username
  #   avatar
  # title: the latest version of the title
  # description: the latest version of the description
  # descriptionAttachments: list of
  #   _id
  # descriptionMentions: list of
  #   _id
  # changes: list (the last list item is the most recent one) of changes
  #   updatedAt: timestamp of the change
  #   author: author of the change
  #     _id
  #     username
  #     avatar
  #   title
  #   description
  #   passingMotions
  #   closingNote
  # meetings: list, if a discussion is associated with a meeting (or meetings) (reverse field from Meeting.discussions.discussion)
  #   _id
  # motions: list, associated motion (or motions) (reverse field from Motion.discussion)
  #   _id
  # motionsCount
  # comments: list, associated comment (or comments) (reverse field from Comment.discussion)
  #   _id
  # commentsCount
  # points: list, associated point (or points) (reverse field from Point.discussion)
  #   _id
  # pointsCount
  # discussionOpenedBy:
  #   _id
  #   username
  #   avatar
  # discussionOpenedAt: time when discussion started
  # discussionClosedBy:
  #   _id
  #   username
  #   avatar
  # discussionClosedAt: time when discussion ended
  # passingMotions: list of motions which passed
  # closingNote: the latest version of the closing note
  # closingNoteAttachments: list of
  #   _id
  # closingNoteMentions: list of
  #   _id
  # status: one of Discussion.STATUS values
  # followers: list of
  #   user:
  #     _id
  #   reason: the first reason for following, or the last manual setting, one of Discussion.REASON values
  # followersCount

  @Meta
    name: 'Discussion'
    fields: =>
      author: @ReferenceField User, User.REFERENCE_FIELDS()
      passingMotions: [@ReferenceField Motion]
      changes: [
        author: @ReferenceField User, User.REFERENCE_FIELDS(), false
      ]
      discussionOpenedBy: @ReferenceField User, User.REFERENCE_FIELDS(), false
      discussionClosedBy: @ReferenceField User, User.REFERENCE_FIELDS(), false
      descriptionAttachments: [
        @ReferenceField StorageFile
      ]
      descriptionMentions: [
        @ReferenceField User
      ]
      closingNoteAttachments: [
        @ReferenceField StorageFile
      ]
      closingNoteMentions: [
        @ReferenceField User
      ]
      followers: [
        user: @ReferenceField User
      ]
    generators: =>
      # $slice in the projection is not supported by Meteor, so we fetch all changes and manually read the latest entry.
      title: @GeneratedField 'self', ['changes'], (fields) =>
        lastChange = fields.changes?[fields.changes?.length - 1]
        return [] unless lastChange and 'title' of lastChange
        [fields._id, lastChange.title or '']
      description: @GeneratedField 'self', ['changes'], (fields) =>
        lastChange = fields.changes?[fields.changes?.length - 1]
        return [] unless lastChange and 'description' of lastChange
        [fields._id, lastChange.description or '']
      passingMotions: [
        @GeneratedField 'self', ['changes'], (fields) =>
          lastChange = fields.changes?[fields.changes?.length - 1]
          return [] unless lastChange and 'passingMotions' of lastChange
          [fields._id, lastChange.passingMotions or []]
      ]
      closingNote: @GeneratedField 'self', ['changes'], (fields) =>
        lastChange = fields.changes?[fields.changes?.length - 1]
        return [] unless lastChange and 'closingNote' of lastChange
        [fields._id, lastChange.closingNote or '']
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
      closingNoteAttachments: [
        @GeneratedField 'self', ['closingNote'], (fields) =>
          return [fields._id, []] unless fields.closingNote
          [fields._id, ({_id} for _id in @extractAttachments fields.closingNote)]
      ]
      closingNoteMentions: [
        @GeneratedField 'self', ['body'], (fields) =>
          return [fields._id, []] unless fields.body
          [fields._id, ({_id} for _id in @extractMentions fields.body)]
      ]
      motionsCount: @GeneratedField 'self', ['motions'], (fields) =>
        [fields._id, fields.motions?.length or 0]
      commentsCount: @GeneratedField 'self', ['comments'], (fields) =>
        [fields._id, fields.comments?.length or 0]
      pointsCount: @GeneratedField 'self', ['points'], (fields) =>
        [fields._id, fields.points?.length or 0]
      status: @GeneratedField 'self', ['discussionOpenedAt', 'discussionOpenedBy', 'discussionClosedAt', 'discussionClosedBy', 'passingMotions', 'closingNote', 'motions'], (fields) =>
        discussion = new Discussion fields
        if discussion.isClosed()
          if fields.passingMotions?.length
            return [fields._id, Discussion.STATUS.PASSED]
          else
            return [fields._id, Discussion.STATUS.CLOSED]
        else if discussion.isOpen()
          # If any motion is open for voting, discussion is open for voting as well.
          if _.some discussion.motions, ((motion) -> motion.status is Motion.STATUS.OPEN)
            return [fields._id, Discussion.STATUS.VOTING]
          # If any motion is being drafted, discussion's motions are being drafted.
          else if _.some discussion.motions, ((motion) -> motion.status is Motion.STATUS.DRAFT)
            return [fields._id, Discussion.STATUS.MOTIONS]
          else
            return [fields._id, Discussion.STATUS.OPEN]
        else
          return [fields._id, Discussion.STATUS.DRAFT]
      followersCount: @GeneratedField 'self', ['followers'], (fields) =>
        followers = (follower for follower in (fields.followers or []) when @isFollower follower)
        [fields._id, followers.length]
    triggers: =>
      updatedAt: share.UpdatedAtTrigger ['changes']
      followMentionedUsersInDescription: share.MentionsTrigger 'descriptionMentions', '_id'
      followMentionedUsersInClosingNote: share.MentionsTrigger 'closingNoteMentions', '_id'

  @PUBLISH_FIELDS: ->
    if userId = Meteor.userId()
      followers =
        followers:
          $elemMatch:
            'user._id': userId
    else
      followers = {}

    _.extend super, followers,
      _id: 1
      createdAt: 1
      updatedAt: 1
      lastActivity: 1
      author: 1
      title: 1
      description: 1
      meetings: 1
      discussionOpenedBy: 1
      discussionOpenedAt: 1
      discussionClosedBy: 1
      discussionClosedAt: 1
      passingMotions: 1
      closingNote: 1
      motionsCount: 1
      commentsCount: 1
      pointsCount: 1
      status: 1
      followersCount: 1

  @STATUS:
    DRAFT: 'draft'
    OPEN: 'open'
    # Motions are being drafted.
    MOTIONS: 'motions'
    # Motions are being voted on (at least one is open).
    VOTING: 'voting'
    CLOSED: 'closed'
    PASSED: 'passed'

  @REASON:
    AUTHOR: 'author'
    MENTIONED: 'mentioned'
    # Manually started following a discussion.
    FOLLOWED: 'followed'
    # Made a comment, point, or a motion, or modified a discussion.
    # But not if only voted on a motion, or upvoted content.
    # Modifying a comment, point, or a motion also does not count.
    PARTICIPATED: 'participated'
    IGNORING: 'ignoring'
    # Ignoring, but notify for mentions.
    MENTIONS: 'mentions'

  @isFollower: (follower) ->
    follower?.reason in [@REASON.AUTHOR, @REASON.MENTIONED, @REASON.FOLLOWED, @REASON.PARTICIPATED, @REASON.MENTIONS]

  @isFollowing: (reason) ->
    reason and reason in [@REASON.AUTHOR, @REASON.MENTIONED, @REASON.FOLLOWED, @REASON.PARTICIPATED]

  @isOnlyMentions: (reason) ->
    reason and reason in [@REASON.MENTIONS]

  @isIgnoring: (reason) ->
    reason and reason in [@REASON.IGNORING]

  @isNotFollowing: (reason) ->
    not reason or reason not in [@REASON.AUTHOR, @REASON.MENTIONED, @REASON.FOLLOWED, @REASON.PARTICIPATED, @REASON.MENTIONS, @REASON.IGNORING]

  isOpen: ->
    !!(@discussionOpenedAt and @discussionOpenedBy and not @discussionClosedAt and not @discussionClosedBy and (not @passingMotions or @passingMotions.length is 0) and not @closingNote)

  isClosed: ->
    !!(@discussionOpenedAt and @discussionOpenedBy and @discussionClosedAt and @discussionClosedBy)

if Meteor.isServer
  Discussion.Meta.collection._ensureIndex
    createdAt: 1

  Discussion.Meta.collection._ensureIndex
    updatedAt: 1

  Discussion.Meta.collection._ensureIndex
    lastActivity: 1

  Discussion.Meta.collection._ensureIndex
    status: 1
