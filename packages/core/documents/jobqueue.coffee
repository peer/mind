JobsWorker.initialize()

# Document is wrapping jobCollection collection so additional fields might be added by
# future versions of the package. An actual schema can be found in validJobDoc function,
# see https://github.com/vsivsi/meteor-job-collection/blob/master/src/shared.coffee#L52
# Fields listed below are partially documented, mostly those which we are using
# elsewhere around our code.
class JobQueue extends share.BaseDocument
  # runId: ID of the current run
  # type: one of Job class names
  # status: status of the job
  # data: arbitrary object with data for the job
  #   motion: optional reference to the motion this job is associated with
  # result: arbitrary object with result
  #   tally: optional reference to the tally this job computed
  # failures: information about job failures
  #   value
  #   stack
  #   runId
  # priority: priority, lower is higher
  # depends: list of job dependencies
  # resolved: list of resolved job dependencies
  # after: should run after this time
  # updated: was updated at this time
  # workTimeout
  # expiresAfter
  # log: list of log entries
  #   time
  #   runId
  #   level
  #   message
  #   data
  # progress:
  #   completed
  #   total
  #   percent
  # retries
  # retried
  # retryUntil
  # retryWait
  # retryBackoff
  # repeats
  # repeated
  # repeatUntil
  # repeatWait
  # created

  @Meta
    name: 'JobQueue'
    collection: JobsWorker.collection
    fields: =>
      # Data can be arbitrary object, but we have one field which
      # we can use if job is referencing a motion.
      data:
        motion: @ReferenceField Motion, [], false
      result:
        tally: @ReferenceField Tally, [], false

# Some indexes are ensured by JobsWorker.initialize.
