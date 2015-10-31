# JobsWorker.initialize is called in documents/jobqueue.coffee.

Meteor.startup ->
  JobsWorker.start()
