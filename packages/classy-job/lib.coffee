class JobsWorker
  @collection: null

  @initialize: ->
    @collection = new (share.JobCollection or JobCollection)('JobQueue', noCollectionSuffix: true)
