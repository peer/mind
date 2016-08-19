Package.describe({
  name: 'instrument',
  version: '0.1.0'
});

Package.onUse(function (api) {
  api.versionsFrom('1.4.1');

  // Core dependencies.
  api.use([
    'coffeescript',
    'underscore-extra'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:flow-router@2.12.1_1',
    'peerlibrary:check-extension@0.2.0'
  ]);

  // Internal dependencies.
  api.use([
    'core'
  ]);

  api.addFiles([
    'router.coffee'
  ], 'client');

  api.addFiles([
    'api.coffee',
    'connections.coffee'
  ], 'server');
});
