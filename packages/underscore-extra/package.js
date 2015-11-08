Package.describe({
  name: 'underscore-extra',
  version: '0.1.0'
});

Package.onUse(function (api) {
  api.versionsFrom('1.2.0.2');

  // Core dependencies.
  api.use([
    'coffeescript',
    'underscore'
  ]);

  api.imply('underscore');

  api.addFiles([
    'underscore.coffee'
  ]);
});
