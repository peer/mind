Call `JobsWorker.initialize()` in your app on both client and server to initialize the worker environment and
`JobsWorker.collection` collection.

Possible options for `JobsWorker.initialize` with defaults:

```javascript
JobsWorker.initialize({
  collectionName: 'JobQueue',
  workerInstances: parseInt(process.env.WORKER_INSTANCES || '1'),
  stalledJobCheckInterval: 60 * 1000, // ms
  promoteInterval: 15 * 1000 // ms
});
```

You can use `WORKER_INSTANCES` environment variable or `workerInstances` option to control how many workers are enabled
across all Meteor instances for your app. If set to `0` the current Meteor instance will not run a worker.

Call `JobsWorker.start` on the server to start the worker:

```javascript
Meteor.startup(function () {
  JobsWorker.start()
});
```

`JobsWorker.start` call will not do anything if `workerInstances` is `0`. Alternativelly, you can simply do not call
`JobsWorker.start`.

Starting is randomly delayed a bit to distribute the behavior of workers equally inside configured intervals.

Jobs are executed serially inside a given worker, one by one.
