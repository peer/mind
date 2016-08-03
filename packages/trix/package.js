Package.describe({
  name: 'trix',
  version: '0.1.0'
});

Package.onUse(function (api) {
  api.versionsFrom('1.4.0.1');

  api.export('Trix', 'client');

  api.addFiles([
    'before.js',
    'vendor/dist/trix.js',
    'after.js',
    'vendor/dist/trix.css'
  ], 'client');
});
