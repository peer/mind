new PublishEndpoint 'Motion.list', (discussionId) ->
  Motion.documents.find
    'discussion._id': discussionId
  ,
    fields: Motion.PUBLISH_FIELDS()
