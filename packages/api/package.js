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
    'upvotable.coffee',
    'meeting/methods.coffee',
    'discussion/methods.coffee',
    'comment/methods.coffee',
    'point/methods.coffee',
    'motion/methods.coffee'
  ]);

  api.addFiles([
    'meeting/publish.coffee',
    'discussion/publish.coffee',
    'comment/publish.coffee',
    'point/publish.coffee',
    'motion/publish.coffee'
  ], 'server');
});
