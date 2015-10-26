class share.JobCollection extends JobCollection
  scrub: (job) ->
    # We make a plain object, to support documents which go through a custom transformation, like a PeerDB transform.
    # We remove _schema field as well, which is added by PeerDB migrations, when enabled.
    _.omit job, '_schema', 'constructor'

  _toLog: (userId, method, message) =>
    @logStream?.write
      timestamp: new Date()
      userId: userId
      method: method
      message: message

  setLogStream: (writeStream) ->
    super

    throw new Error "logStream must be a writable stream in the object mode." if @logStream and not @logStream._writableState.objectMode
