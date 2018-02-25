Package.describe({
  name: 'loading',
  version: '0.1.0'
});

Package.onUse(function (api) {
  api.versionsFrom('1.6.0.1');

  // Core dependencies.
  api.use([
    'static-html',
    'stylus',
    'coffeescript',
    'jquery'
  ], 'client');

  api.addFiles([
    'loading.html',
    'loading.coffee',
    'loading.styl'
  ], 'client');
});
