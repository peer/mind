Package.describe({
  name: 'core',
  version: '0.1.0'
});

Npm.depends({
  'svg2img': '0.2.5'
});

Package.onUse(function (api) {
  api.versionsFrom('1.4.1');

  // Core dependencies.
  api.use([
    'coffeescript',
    'accounts-base',
    'jquery',
    'random',
    'ddp',
    'modules',
    'spacebars'
  ]);

  api.use([
    // We depend weakly, so that we can use Email symbol for our document class.
    'email'
  ], 'server', {weak: true});

  // 3rd party dependencies.
  api.use([
    'peerlibrary:peerdb@0.23.0',
    'peerlibrary:peerdb-migrations@0.3.0',
    'peerlibrary:meteor-file@0.2.1',
    'peerlibrary:reactive-field@0.3.0',
    'peerlibrary:assert@0.2.5',
    // TODO: There is a newer version of cheerio, but not Meteor package. Upgrade.
    'fermuch:cheerio@0.19.0',
    'alanning:roles@1.2.15',
    'peerlibrary:classy-job@0.6.2',
    'peerlibrary:user-extra@0.1.0',
    'kenton:accounts-sandstorm@0.5.1',
    'peerlibrary:blocking@0.5.2'
  ]);

  api.use([
    'peerlibrary:crypto@0.2.1'
  ], 'server');

  // Internal dependencies.
  api.use([
    'underscore-extra',
    'voting',
    'storage',
    'sanitize'
  ]);

  // To break a dependency cycle.
  api.use([
    'jobs'
  ], {unordered: true});

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
  api.export('Email');

  api.addFiles([
    'worker.coffee',
    'roles.coffee',
    'account.coffee',
    'sandstorm-server.coffee',
    'version.coffee'
  ], 'server');

  api.addFiles([
    'sandstorm-client.coffee',
    'meteor-bugfix.coffee'
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
    'documents/email.coffee',
    'finalize-documents.coffee'
  ]);

  api.addFiles([
    'migrations/0001-user-avatars.coffee',
    'migrations/0002-user-avatar.coffee',
    'migrations/0003-user-researchdata.coffee',
    'migrations/0004-point-body.coffee',
    'migrations/0005-point-bodydisplay.coffee',
    'migrations/0006-discussion-meetings.coffee',
    'migrations/0007-motion-upvotes.coffee',
    'migrations/0008-motion-upvotescount.coffee',
    'migrations/0009-discussion-closing.coffee',
    'migrations/0010-discussion-opened.coffee',
    'migrations/0011-motion-status.coffee',
    'migrations/0012-discussion-generated.coffee',
    'migrations/0013-upvotable-status.coffee',
    'migrations/0014-user-changes.coffee',
    'migrations/0015-user-profile.coffee',
    'migrations/0016-displayfields.coffee',
    'migrations/0017-vote-motion.coffee',
    'migrations/0018-tally-infavor.coffee',
    'migrations/0019-meeting-discussions.coffee',
    'migrations/0020-activity-type.coffee',
    'migrations/0021-activity-document.coffee',
    'migrations/0022-activity-data.coffee',
    'migrations/0023-activity-byuser.coffee',
    'migrations/0024-attachments.coffee',
    'migrations/0025-mentions.coffee',
    'migrations/0026-discussion-followers.coffee',
    'migrations/0027-discussion-followerscount.coffee',
    'migrations/0028-activity-forusers.coffee',
    'migrations/0029-activity.coffee',
    'migrations/0030-user-lastseenpersonalizedactivity.coffee',
    'migrations/0031-activity-data.coffee',
    'migrations/0032-user-lastseendiscussion.coffee',
    'migrations/0033-user-lastseenmeeting.coffee',
    'migrations/0034-user-name.coffee',
    'migrations/0035-activity-levels.coffee',
    'migrations/0036-user-delegations.coffee',
    'migrations/0037-user-avatars.coffee',
    'migrations/0038-activity-discussionsmeetings.coffee',
    'migrations/0039-user-emailnotifications.coffee',
    'migrations/0040-user-discussionfollowing.coffee'
  ], 'server');
});

Package.onTest(function (api) {
  api.versionsFrom('1.4.1');

  // Core dependencies.
  api.use([
    'coffeescript',
    'random',
    'ejson'
  ]);

  // Internal dependencies.
  api.use([
    'core'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:classy-test@0.2.26'
  ]);

  api.addFiles([
    'tests.coffee'
   ]);
});
