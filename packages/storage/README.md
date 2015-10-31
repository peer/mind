Call `Storage.initialize()` in your app on both client and server to initialize the storage environment.

Possible options for `Storage.initialize` with defaults:

```javascript
Storage.initialize({
  storagePath: '/storage',
  maxAge: 24 * 60 * 60 * 1000, // ms
  storageDirectory: process.env.STORAGE_DIRECTORY || '.meteor/storage/'
});
```
