Package.describe({
  name: 'instrument',
  version: '0.1.0'
});

Package.onUse(function (api) {
  api.versionsFrom('1.4.1');

  // Core dependencies.
  api.use([
    'coffeescript',
    'underscore-extra',
    'accounts-base',
    'jquery',
    'promise',
    'modules'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:flow-router@2.12.1_1',
    'peerlibrary:check-extension@0.2.0',
    'doctorpangloss:method-hooks@2.0.2',
    'peerlibrary:stacktrace@1.3.1_2'
  ]);

  // Internal dependencies.
  api.use([
    'core'
  ]);

  api.addFiles([
    'router.coffee',
    'errors.coffee'
  ], 'client');

  api.addFiles([
    'api.coffee',
    'connections.coffee',
    'accounts.coffee'
  ], 'server');
});
