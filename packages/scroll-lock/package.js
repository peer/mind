Package.describe({
  name: 'scroll-lock',
  summary: "A jQuery plugin for preventing of scrolling of parent element",
  version: '0.1.0'
});

Package.onUse(function(api) {
  api.versionsFrom('1.6.0.1');

    // Core dependencies.
  api.use([
    'jquery'
  ]);

  // Internal dependencies.
  api.use([
    'mousewheel'
  ]);

  api.addFiles([
    'jquery.scroll-lock.js'
  ], 'client');
});
