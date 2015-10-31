`WORKER_INSTANCES` environment variable controls how many workers are enabled across all Meteor instances for your
app. If set to `0` the current Meteor instance will not run a worker.

Call `JobsWorker.initialize()` in your app on both client and server to initialize the worker environment and collection.
Call `JobsWorker.start` to start the worker:

```javascript
Meteor.startup(function () {
  JobsWorker.start()
});
```

`JobsWorker.start` call will not do anything if `WORKER_INSTANCES` is set to `0`. Or you can simply do not call
`JobsWorker.start`.

Jobs are executed serially inside a given worker.
