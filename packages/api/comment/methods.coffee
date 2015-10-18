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
