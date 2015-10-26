jobCollectionJob = Job

class JobsWorker
  @collection: null

  @initialize: ->
    @collection = new (share.JobCollection or JobCollection)('JobQueue', noCollectionSuffix: true)

  @makeJob: (document) ->
    new jobCollectionJob @collection, document

  @createJob: (type, data) ->
    new jobCollectionJob @collection, type, data
