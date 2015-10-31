jobCollectionJob = Job

class JobsWorker
  @DEFAULT_JOBS_COLLECTION: 'JobQueue'

  @collection: null

  @initialize: (@options={}) ->
    @options = _.defaults {}, @options,
      collectionName: @DEFAULT_JOBS_COLLECTION

    @collection = new (share.JobCollection or JobCollection)(@options.collectionName, noCollectionSuffix: true)

  @_makeJob: (document) ->
    new jobCollectionJob @collection, document

  @_createJob: (type, data) ->
    new jobCollectionJob @collection, type, data
