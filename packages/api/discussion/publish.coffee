new PublishEndpoint 'Discussion.list', ->
  Discussion.documents.find {},
    fields: Discussion.PUBLISH_FIELDS()

