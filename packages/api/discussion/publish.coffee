new PublishEndpoint 'Discussion.list', ->
  Discussion.documents.find {},
    fields: Discussion.PUBLISH_FIELDS()

new PublishEndpoint 'Discussion.one', (discussionId) ->
  check discussionId, Match.DocumentId

  Discussion.documents.find discussionId,
    fields: Discussion.PUBLISH_FIELDS()

new PublishEndpoint 'Discussion.unseenCount', ->
  userId = Meteor.userId()

  return [] unless userId

  lastSeenDiscussion = new ComputedField =>
    User.documents.findOne(userId,
      fields:
        lastSeenDiscussion: 1
    )?.lastSeenDiscussion or null
  ,
    true

  @onStop =>
    lastSeenDiscussion.stop()

  @autorun (computation) =>
    # TODO: Limit only to those which are displayed when clicking "discussions" in the menu.
    #       I.e., only non-closed discussions.
    query =
      'author._id':
        $ne: userId
    if lastSeenDiscussion()
      _.extend query,
        createdAt:
          $gt: lastSeenDiscussion()

    @setData 'count', Math.min Discussion.documents.find(query).count(), 999

  @ready()
