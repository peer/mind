Package.describe({
  name: 'core',
  version: '0.1.0'
});

Package.onUse(function (api) {
  api.versionsFrom('1.4.1');

  // Core dependencies.
  api.use([
    'coffeescript',
    'accounts-base',
    'underscore-extra',
    'jquery',
    'random',
    'ddp',
    'modules'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:peerdb@0.22.1',
    'peerlibrary:peerdb-migrations@0.2.1',
    'peerlibrary:meteor-file@0.2.1',
    'peerlibrary:reactive-field@0.1.0',
    'peerlibrary:assert@0.2.5',
    // TODO: There is a newer version of cheerio, but not Meteor package. Upgrade.
    'fermuch:cheerio@0.19.0',
    'alanning:roles@1.2.15',
    'peerlibrary:classy-job@0.5.0',
    'peerlibrary:user-extra@0.1.0',
    'kenton:accounts-sandstorm@0.5.1'
  ]);

  api.use([
    'peerlibrary:crypto@0.2.1'
  ], 'server');

  // Internal dependencies.
  api.use([
    'voting',
    'jobs',
    'storage',
    'sanitize'
  ]);

  api.export('User');
  api.export('Discussion');
  api.export('Meeting');
  api.export('Comment');
  api.export('Point');
  api.export('Motion');
  api.export('Vote');
  api.export('Tally');
  api.export('JobQueue');
  api.export('StorageFile');
  api.export('Activity');
  api.export('Admin');
  api.export('Settings');

  api.addFiles([
    'worker.coffee',
    'roles.coffee',
    'account.coffee',
    'sandstorm-server.coffee',
    'version.coffee'
  ], 'server');

  api.addFiles([
    'sandstorm-client.coffee'
  ], 'client');

  api.addFiles([
    'base.coffee',
    'upvotable.coffee',
    'triggers.coffee',
    'storage.coffee',
    'admin.coffee',
    'settings.coffee',
    'documents/user.coffee',
    'documents/discussion.coffee',
    'documents/meeting.coffee',
    'documents/comment.coffee',
    'documents/point.coffee',
    'documents/motion.coffee',
    'documents/vote.coffee',
    'documents/tally.coffee',
    'documents/jobqueue.coffee',
    'documents/storagefile.coffee',
    'documents/activity.coffee',
    'finalize-documents.coffee'
  ]);
});
