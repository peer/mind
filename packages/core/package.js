Package.describe({
  name: 'core',
  version: '0.1.0'
});

Package.onUse(function (api) {
  api.versionsFrom('1.0.3.1');

  // Core dependencies.
  api.use([
    'coffeescript',
    'accounts-base'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:peerdb@0.19.1'
  ]);

  // Internal dependencies.
  api.use([
  ]);

  api.export('Discussion');
  api.export('Meeting');
  api.export('User');

  api.addFiles([
    'documents/base.coffee',
    'documents/discussion.coffee',
    'documents/meeting.coffee',
    'documents/user.coffee'
  ]);
});
