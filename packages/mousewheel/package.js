Package.describe({
  name: 'mousewheel',
  summary: "A jQuery plugin that adds cross-browser mouse wheel support",
  version: '3.1.13_1'
});

Package.onUse(function(api) {
  api.versionsFrom('1.6.0.1');

    // Core dependencies.
  api.use([
    'jquery'
  ]);

  api.addFiles([
    'vendor/jquery.mousewheel.js'
  ], 'client');
});
