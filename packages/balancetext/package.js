Package.describe({
  name: 'balancetext',
  summary: "A jQuery plugin for implementing balancing of wrapping text in a web page",
  version: '2.0.0_1'
});

Package.onUse(function(api) {
  api.versionsFrom('1.4.1');

    // Core dependencies.
  api.use([
    'jquery'
  ]);

  api.addFiles([
    'vendor/jquery.balancetext.js'
  ], 'client');
});
