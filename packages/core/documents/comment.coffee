class Comment extends share.UpvotableDocument
  # createdAt: time of document creation
  # updatedAt: time of the last change
  # lastActivity: time of the last activity on the comment
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

  @Meta
    name: 'Comment'
    fields: (fields) =>
      _.extend fields,
        bodyDisplay: @GeneratedField 'self', ['body'], (fields) =>
          [fields._id, fields.body and @sanitizeForDisplay.sanitizeHTML fields.body]
        bodyAttachments: [
          # TODO: Make it an array of references to StorageFile as well.
          @GeneratedField 'self', ['body'], (fields) =>
            return [fields._id, []] unless fields.body
            [fields._id, ({_id} for _id in @extractAttachments fields.body)]
        ]

  @PUBLISH_FIELDS: ->
    _.extend super,
      bodyDisplay: 1

if Meteor.isServer
  Comment.Meta.collection._ensureIndex
    createdAt: 1

  Comment.Meta.collection._ensureIndex
    updatedAt: 1

  Comment.Meta.collection._ensureIndex
    lastActivity: 1

  Comment.Meta.collection._ensureIndex
    upvotesCount: 1
