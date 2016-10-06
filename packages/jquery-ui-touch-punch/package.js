Package.describe({
  name: 'jquery-ui-touch-punch',
  summary: "A duck punch for adding touch events to jQuery UI",
  version: '0.2.3_1'
});

Package.onUse(function(api) {
  api.versionsFrom('1.4.1.2');

  // Core dependencies.
  api.use([
    'jquery'
  ]);

  // 3rd party dependencies.
  api.use([
    'mizzao:jquery-ui@1.11.4'
  ]);

  api.addFiles([
    'vendor/jquery.ui.touch-punch.js'
  ], 'client');
});
