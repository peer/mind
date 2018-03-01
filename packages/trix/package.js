Package.describe({
  name: 'trix',
  version: '0.1.0'
});

Package.onUse(function (api) {
  api.versionsFrom('1.6.0.1');

  // Core dependencies.
  api.use([
    'modules'
  ]);

  api.export('Trix', 'client');

  api.addFiles([
    'index.js',
    'vendor/dist/trix.css'
  ], 'client');
});
