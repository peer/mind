Package.describe({
  name: 'storage',
  version: '0.1.0'
});

Package.onUse(function (api) {
  api.versionsFrom('1.4.1');

  // Core dependencies.
  api.use([
    'coffeescript',
    'webapp'
  ]);

  // 3rd party dependencies.
  api.use([
    // TODO: Enable when this is resolved: https://github.com/peerlibrary/meteor-fs/issues/2
    // 'peerlibrary:fs@0.1.7',
    'peerlibrary:assert@0.2.5',
    'peerlibrary:connect@2.28.1_1',
    'peerlibrary:blocking@0.5.2'
  ]);
  api.use([
    'peerlibrary:flow-router@2.10.0_2'
  ], {weak: true});

  // Internal dependencies.
  api.use([
    'underscore-extra'
  ]);

  api.export('Storage');

  api.addFiles([
    'lib.coffee'
  ]);

  api.addFiles([
    'server.coffee'
  ], 'server');
});
