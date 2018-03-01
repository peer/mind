Package.describe({
  name: 'api',
  version: '0.1.0'
});

Npm.depends({
  'mime-types': '2.1.6'
});

Package.onUse(function (api) {
  api.versionsFrom('1.6.0.1');

  // Core dependencies.
  api.use([
    'coffeescript',
    'accounts-base',
    'accounts-password',
    'random',
    'jquery',
    'ejson'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:middleware@0.1.1',
    'peerlibrary:reactive-publish@0.5.0',
    'peerlibrary:check-extension@0.3.0',
    'peerlibrary:assert@0.2.5',
    // TODO: There is a newer version of cheerio, but not Meteor package. Upgrade.
    'fermuch:cheerio@0.19.0',
    'peerlibrary:meteor-file@0.2.1',
    'doctorpangloss:method-hooks@2.0.2',
    'peerlibrary:subscription-scope@0.3.0',
    'peerlibrary:subscription-data@0.6.1',
    'peerlibrary:computed-field@0.7.0'
  ]);

  // Internal dependencies.
  api.use([
    'underscore-extra',
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
    'motion/methods.coffee',
    'activity/methods.coffee',
    'user/methods.coffee',
    'account/methods.coffee'
  ]);

  api.addFiles([
    'meeting/publish.coffee',
    'discussion/publish.coffee',
    'comment/publish.coffee',
    'point/publish.coffee',
    'motion/publish.coffee',
    'user/publish.coffee',
    'activity/publish.coffee'
  ], 'server');

  // Methods which have to be or we prefer server-side.
  api.addFiles([
    'storagefile/methods-server.coffee',
    'user/methods-server.coffee',
    'account/methods-server.coffee',
    'base/methods-server.coffee'
  ], 'server');
});
