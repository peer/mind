Meteor.methods
  'Comment.new': (document) ->
    share.newUpvotable Comment, document,
      body: Match.NonEmptyString
      discussion:
        _id: Match.DocumentId

  'Comment.upvote': (commentId) ->
    share.upvoteUpvotable Comment, commentId

  'Comment.removeUpvote': (commentId) ->
    share.removeUpvoteUpvotable Comment, commentId

  'Comment.update': (document) ->
    check document,
      _id: Match.DocumentId
      body: Match.NonEmptyString

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    # TODO: Should we also allow moderators to update comments?
    updatedAt = new Date()
    Comment.documents.update
      _id: document._id
      'author._id': user._id
      body:
        $ne: document.body
    ,
      $set:
        updatedAt: updatedAt
        body: document.body
      $push:
        changes:
          updatedAt: updatedAt
          author: user.getReference()
          body: document.body
