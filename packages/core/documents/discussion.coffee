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
  #   description
  #   closingMotions
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
  # closingMotions: list of motions which were selected to close
  # closingNote: the latest version of the closing note
  # closingNoteDisplay: HTML content of the closing note without tags needed for editing
  # closingNoteAttachments: list of
  #   _id

  @Meta
    name: 'Discussion'
    fields: =>
      author: @ReferenceField User, User.REFERENCE_FIELDS()
      # $slice in the projection is not supported by Meteor, so we fetch all changes and manually read the latest entry.
      title: @GeneratedField 'self', ['changes'], (fields) =>
        lastChange = fields.changes?[fields.changes?.length - 1]
        return [] unless lastChange and 'title' of lastChange
        [fields._id, lastChange.title or '']
      description: @GeneratedField 'self', ['changes'], (fields) =>
        lastChange = fields.changes?[fields.changes?.length - 1]
        return [] unless lastChange and 'description' of lastChange
        [fields._id, lastChange.description or '']
      closingMotions: @GeneratedField 'self', ['changes'], (fields) =>
        lastChange = fields.changes?[fields.changes?.length - 1]
        return [] unless lastChange and 'closingMotions' of lastChange
        [fields._id, lastChange.closingMotions or []]
      closingNote: @GeneratedField 'self', ['changes'], (fields) =>
        lastChange = fields.changes?[fields.changes?.length - 1]
        return [] unless lastChange and 'closingNote' of lastChange
        [fields._id, lastChange.closingNote or []]
      descriptionDisplay: @GeneratedField 'self', ['description'], (fields) =>
        [fields._id, fields.description and @sanitizeForDisplay.sanitizeHTML fields.description]
      descriptionAttachments: [
        # TODO: Make it an array of references to StorageFile as well.
        @GeneratedField 'self', ['description'], (fields) =>
          return [fields._id, []] unless fields.description
          [fields._id, ({_id} for _id in @extractAttachments fields.description)]
      ]
      closingNoteDisplay: @GeneratedField 'self', ['closingNote'], (fields) =>
        [fields._id, fields.closingNote and @sanitizeForDisplay.sanitizeHTML fields.closingNote]
      closingNoteAttachments: [
        # TODO: Make it an array of references to StorageFile as well.
        @GeneratedField 'self', ['closingNote'], (fields) =>
          return [fields._id, []] unless fields.closingNote
          [fields._id, ({_id} for _id in @extractAttachments fields.closingNote)]
      ]
      closingMotions: [@ReferenceField Motion]
      changes: [
        author: @ReferenceField User, User.REFERENCE_FIELDS(), false
      ]
      motionsCount: @GeneratedField 'self', ['motions'], (fields) ->
        [fields._id, fields.motions?.length or 0]
      commentsCount: @GeneratedField 'self', ['comments'], (fields) ->
        [fields._id, fields.comments?.length or 0]
      pointsCount: @GeneratedField 'self', ['points'], (fields) ->
        [fields._id, fields.points?.length or 0]
    triggers: =>
      updatedAt: share.UpdatedAtTrigger ['changes']

  @PUBLISH_FIELDS: ->
    _.extend super,
      _id: 1
      createdAt: 1
      updatedAt: 1
      lastActivity: 1
      author: 1
      title: 1
      descriptionDisplay: 1
      meetings: 1

if Meteor.isServer
  Discussion.Meta.collection._ensureIndex
    createdAt: 1

  Discussion.Meta.collection._ensureIndex
    updatedAt: 1

  Discussion.Meta.collection._ensureIndex
    lastActivity: 1
