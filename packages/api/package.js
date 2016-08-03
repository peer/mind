Package.describe({
  name: 'api',
  version: '0.1.0'
});

Npm.depends({
  'mime-types': '2.1.6'
});

Package.onUse(function (api) {
  api.versionsFrom('1.4.0.1');

  // Core dependencies.
  api.use([
    'coffeescript',
    'accounts-base',
    'underscore-extra',
    'random',
    'jquery'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:middleware@0.1.1',
    'peerlibrary:reactive-publish@0.3.0',
    'peerlibrary:check-extension@0.2.0',
    'peerlibrary:assert@0.2.5',
    // TODO: There is a newer version of cheerio, but not Meteor package. Upgrade.
    'fermuch:cheerio@0.19.0',
    'peerlibrary:meteor-file@0.2.1'
  ]);

  // Internal dependencies.
  api.use([
    'core',
    'voting',
    'storage'
  ]);

  api.addFiles([
    'base/upvotable.coffee',
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
    'motion/publish.coffee',
    'storagefile/methods.coffee',
    'user/publish.coffee',
    'user/methods.coffee'
  ], 'server');
});
