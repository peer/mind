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

new PublishEndpoint 'Meeting.forEdit', (meetingId) ->
  check meetingId, Match.DocumentId

  # TODO: Allow only for those who can edit the meeting?

  Meeting.documents.find
    _id: meetingId
  ,
    fields:
      description: 1
