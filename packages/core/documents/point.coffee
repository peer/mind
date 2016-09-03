class Point extends share.UpvotableDocument
  # createdAt: time of document creation
  # updatedAt: time of the last change
  # lastActivity: time of the last activity on the comment
  # author:
  #   _id
  #   username
  #   avatar
  # discussion:
  #   _id
  #   status
  # body: the latest version of the body
  # bodyAttachments: list of
  #   _id
  # changes: list (the last list item is the most recent one) of changes
  #   updatedAt: timestamp of the change
  #   author: author of the change
  #     _id
  #     username
  #     avatar
  #   body
  #   category
  # upvotes: list of
  #   createdAt: timestamp of the upvote
  #   author: author of the upvote
  #     _id
  # upvotesCount
  # category: one of "infavor", "against", and "other"

  @Meta
    name: 'Point'
    fields: (fields) =>
      _.extend fields,
        # $slice in the projection is not supported by Meteor, so we fetch all changes and manually read the latest entry.
        category: @GeneratedField 'self', ['changes'], (fields) =>
          lastChange = fields.changes?[fields.changes?.length - 1]
          return [] unless lastChange and 'category' of lastChange
          [fields._id, lastChange.category or Point.CATEGORY.OTHER]
        # We override this field with one with a reverse field.
        discussion: @ReferenceField Discussion, ['status'], true, 'points', []

  @CATEGORY:
    IN_FAVOR: 'infavor'
    AGAINST: 'against'
    OTHER: 'other'

  @PUBLISH_FIELDS: ->
    _.extend super,
      category: 1

if Meteor.isServer
  Point.Meta.collection._ensureIndex
    createdAt: 1

  Point.Meta.collection._ensureIndex
    updatedAt: 1

  Point.Meta.collection._ensureIndex
    lastActivity: 1

  Point.Meta.collection._ensureIndex
    upvotesCount: 1
