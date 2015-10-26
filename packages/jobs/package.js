Package.describe({
  name: 'jobs',
  version: '0.1.0'
});

Package.onUse(function (api) {
  api.versionsFrom('1.2.0.2');

  // Core dependencies.
  api.use([
    'coffeescript'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:assert@0.2.5'
  ]);

  // Internal dependencies.
  api.use([
    'voting',
    'classy-job'
  ]);

  api.addFiles([
    'tally.coffee'
  ], 'server');
});
