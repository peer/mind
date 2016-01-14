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
