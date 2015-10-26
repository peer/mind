WritableStream = Npm.require('stream').Writable

WORKER_INSTANCES = parseInt(process.env.WORKER_INSTANCES || '1')
WORKER_INSTANCES = 1 unless _.isFinite WORKER_INSTANCES

STALLED_JOB_CHECK_INTERVAL = 60 * 1000 # ms
PROMOTE_INTERVAL = 15 * 1000 # ms

class JobsWorker extends JobsWorker
  @_jobQueueRunning: false

  @initialize: ->
    super

    # To prevent logging of all calls while keeping logging of errors.
    # TODO: Replace with a better solution which overrides an event handler method.
    #       See https://github.com/vsivsi/meteor-job-collection/pull/123
    @collection._callListener.removeListener 'call', @collection._callListener._events.call[0]

    writableStream = new WritableStream
      objectMode: true

    writableStream._write = (chunk, encoding, callback) =>
      @_log chunk

      callback null

    @collection.setLogStream writableStream

    @collection._ensureIndex
      type: 1
      status: 1

    @collection._ensureIndex
      priority: 1
      retryUntil: 1
      after: 1

  @_log: (data) ->
    {timestamp, userId, method, message} = data

    Log.info "#{method}: #{message}"

  @start: ->
    # Worker is disabled.
    return Log.info "Worker disabled" unless WORKER_INSTANCES

    # We randomly delay start so that not all instances are promoting
    # at the same time, but dispersed over the whole interval.
    Meteor.setTimeout =>
      # Check for promoted jobs at this interval. Jobs scheduled in the
      # future has to be made ready at regular intervals because time-based
      # queries are not reactive. time < NOW, NOW does not change as times go
      # on, once you make a query. More instances we have, less frequently
      # each particular instance should check.
      @collection.promote WORKER_INSTANCES * PROMOTE_INTERVAL

      @_startProcessingJobs()
    ,
      Random.fraction() * WORKER_INSTANCES * PROMOTE_INTERVAL

    # Same deal with delaying and spreading the interval based on
    # the number of worker instances that we have for job promotion.
    Meteor.setTimeout =>
      # We check for stalled jobs ourselves (and not use workTimeout)
      # so that each job class can define a different timeout.
      Meteor.setInterval =>
        @collection.find(status: 'running').forEach (jobQueueItem, index, cursor) =>
          try
            jobClass = Job.types[jobQueueItem.type]
            return if new Date().valueOf() < jobQueueItem.updated.valueOf() + jobClass.timeout

            job = @makeJob jobQueueItem
            job.fail "No progress for more than #{jobClass.timeout / 1000} seconds."
          catch error
            Log.error "Error while canceling a stalled job #{jobQueueItem.type}/#{jobQueueItem._id}: #{error.stack or error}"
      ,
        WORKER_INSTANCES * STALLED_JOB_CHECK_INTERVAL
    ,
      Random.fraction() * WORKER_INSTANCES * STALLED_JOB_CHECK_INTERVAL

  @_startProcessingJobs: ->
    @collection.startJobServer()

    Log.info "Worker enabled"

    # The query and sort here is based on the query in jobCollection's getWork query. We want to have a query which is
    # the same, just that we observe with it and when there is any change, we call getWork itself.
    @collection.find(
      status: 'ready'
      runId: null
    ,
      sort:
        priority: 1
        retryUntil: 1
        after: 1
      fields:
        _id: 1
    ).observeChanges
      added: (id, fields) =>
        @_runJobQueue()

      changed: (id, fields) =>
        @_runJobQueue()

  @_runJobQueue: ->
    return if @_jobQueueRunning
    @_jobQueueRunning = true

    # We defer so that we can return quick so that observe keeps
    # running. We run here in a loop until there is no more work
    # when we go back to observe to wait for next ready job.
    Meteor.defer =>
      try
        loop
          jobs = @collection.getWork _.keys Job.types
          break unless jobs?.length

          for job in jobs
            try
              try
                jobClass = Job.types[job.type]
                jobInstance = new jobClass job.data
                jobInstance._id = job._doc._id
                jobInstance.runId = job._doc.runId
                result = jobInstance.run()
              catch error
                if error instanceof Error
                  stack = StackTrace.printStackTrace e: error
                  job.fail EJSON.toJSONValue(value: error.message, stack: stack),
                    fatal: error instanceof Job.FatalJobError
                else
                  job.fail EJSON.toJSONValue(value: "#{error}")
                continue
              job.done EJSON.toJSONValue result
            catch error
              Log.error "Error running a job queue: #{error.stack or error}"
      finally
        @_jobQueueRunning = false
