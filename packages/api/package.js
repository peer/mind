Package.describe({
  name: 'api',
  version: '0.1.0'
});

Package.onUse(function (api) {
  api.versionsFrom('1.0.3.1');

  // Core dependencies.
  api.use([
    'coffeescript'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:middleware@0.1.1',
    'peerlibrary:reactive-publish@0.1.1',
    'peerlibrary:check-extension@0.2.0'
  ]);

  // Internal dependencies.
  api.use([
    'core'
  ]);

  api.addFiles([
    'meeting/publish.coffee',
    'meeting/methods.coffee',
    'discussion/publish.coffee',
    'discussion/methods.coffee',
    'comment/publish.coffee',
    'comment/methods.coffee'
  ], 'server');
});
