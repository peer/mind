new PublishEndpoint 'Meeting.list', ->
  Meeting.documents.find {},
    fields: Meeting.PUBLISH_FIELDS()

new PublishEndpoint 'Meeting.one', (documentId) ->
  check documentId, Match.DocumentId

  Meeting.documents.find documentId,
    fields: Meeting.PUBLISH_FIELDS()

new PublishEndpoint 'Meeting.discussion', (meetingId) ->
  check meetingId, Match.DocumentId

  Discussion.documents.find
    'meetings._id': meetingId
  ,
    fields:
      Discussion.PUBLISH_FIELDS()
