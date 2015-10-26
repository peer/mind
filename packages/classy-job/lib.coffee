jobCollectionJob = Job

class JobsWorker
  @collection: null

  @initialize: ->
    @collection = new (share.JobCollection or JobCollection)('JobQueue', noCollectionSuffix: true)

  @_makeJob: (document) ->
    new jobCollectionJob @collection, document

  @_createJob: (type, data) ->
    new jobCollectionJob @collection, type, data
