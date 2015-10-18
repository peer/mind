new PublishEndpoint 'Meeting.list', ->
  Meeting.documents.find {},
    fields: Discussion.PUBLISH_FIELDS()
