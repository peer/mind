new PublishEndpoint 'Meeting.list', ->
  Meeting.documents.find {},
    fields: Meeting.PUBLISH_FIELDS()

new PublishEndpoint 'Meeting.one', (meetingId) ->
  check meetingId, Match.DocumentId

  Meeting.documents.find meetingId,
    fields: Meeting.PUBLISH_FIELDS()

new PublishEndpoint 'Meeting.discussion', (meetingId) ->
  check meetingId, Match.DocumentId

  Discussion.documents.find
    'meetings._id': meetingId
  ,
    fields:
      Discussion.PUBLISH_FIELDS()

new PublishEndpoint 'Meeting.unseenCount', ->
  userId = Meteor.userId()

  return [] unless userId

  lastSeenMeeting = new ComputedField =>
    User.documents.findOne(userId,
      fields:
        lastSeenMeeting: 1
    )?.lastSeenMeeting or null
  ,
    true

  @onStop =>
    lastSeenMeeting.stop()

  @autorun (computation) =>
    query =
      'author._id':
        $ne: userId
    if lastSeenMeeting()
      _.extend query,
        createdAt:
          $gt: lastSeenMeeting()

    @setData 'count', Math.min Meeting.documents.find(query).count(), 999

  @ready()
