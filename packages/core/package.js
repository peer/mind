Package.describe({
  name: 'core',
  version: '0.1.0'
});

Package.onUse(function (api) {
  api.versionsFrom('1.2.0.2');

  // Core dependencies.
  api.use([
    'coffeescript',
    'accounts-base',
    'ddp-client',
    'underscore'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:peerdb@0.19.1'
  ]);

  // Internal dependencies.
  api.use([
  ]);

  api.export('User');
  api.export('Discussion');
  api.export('Meeting');
  api.export('Comment');
  api.export('Point');
  api.export('Motion');
  api.export('Vote');

  api.addFiles([
    'publish.coffee'
  ], 'server');

  api.addFiles([
    'underscore.coffee',
    'base.coffee',
    'upvotable.coffee',
    'triggers.coffee',
    'documents/user.coffee',
    'documents/discussion.coffee',
    'documents/meeting.coffee',
    'documents/comment.coffee',
    'documents/point.coffee',
    'documents/motion.coffee',
    'documents/vote.coffee',
    'finalize-documents.coffee'
  ]);
});
