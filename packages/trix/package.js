Package.describe({
  name: 'trix',
  version: '0.1.0'
});

Package.onUse(function (api) {
  api.versionsFrom('1.2.0.2');

  api.addFiles([
    'vendor/dist/trix.js',
    'vendor/dist/trix.css'
  ], 'client');
});
