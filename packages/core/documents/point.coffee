class Point extends share.UpvotableDocument
  # createdAt: time of document creation
  # updatedAt: time of the last change
  # lastActivity: time of the last activity on the comment
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
  # upvotes: list of
  #   createdAt: timestamp of the upvote
  #   author: author of the upvote
  #     _id
  # upvotesCount
  # category: one of "infavor", "against", and "other"
  # categoryChanges: list (the last list item is the most recent one) of
  #   updatedAt: timestamp of the change
  #   author: author of the change
  #     _id
  #     username
  #   category

  @Meta
    name: 'Point'
    fields: (fields) =>
      # $slice in the projection is not supported by Meteor, so we fetch all changes and manually read the latest entry.
      fields.category = @GeneratedField 'self', ['categoryChanges'], (fields) ->
        [fields._id, fields.categoryChanges?[fields.categoryChanges?.length - 1]?.category or '']
      fields.categoryChanges = [
        author: @ReferenceField User, User.REFERENCE_FIELDS()
      ]
      fields

  @CATEGORY:
    IN_FAVOR: 'infavor'
    AGAINST: 'against'
    OTHER: 'other'

  @PUBLISH_FIELDS: ->
    _.extend super,
      category: 1
