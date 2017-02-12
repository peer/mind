Package.describe({
  name: 'jobs',
  version: '0.1.0'
});

Npm.depends({
  'juice': '3.0.1'
});

Package.onUse(function (api) {
  api.versionsFrom('1.4.1');

  // Core dependencies.
  api.use([
    'coffeescript',
    'http',
    'random',
    'accounts-password',
    'stylus',
    'htmljs',
    'html-tools',
    'underscore'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:assert@0.2.5',
    'alanning:roles@1.2.15',
    'peerlibrary:classy-job@0.6.1',
    'fermuch:cheerio@0.19.0'
  ]);

  // Internal dependencies.
  api.use([
    'ui-components',
    'underscore-extra',
    'voting',
    'core',
    'peermind'
  ]);

  // We want to depend only if instrumentation is enabled, but not force it.
  api.use([
    'instrument'
  ], {weak: true});

  api.export('ComputeTallyJob');
  api.export('ActivityEmailsImmediatelyJob');

  api.addFiles([
    'tally.coffee',
    'email.html',
    'email.coffee'
  ], 'server');

  // Stylesheets can be compiled only for the client.
  api.addFiles([
    'email.styl'
  ], 'client');
});

Package.onTest(function (api) {
  api.versionsFrom('1.4.1');

  // Core dependencies.
  api.use([
    'coffeescript',
    'random'
  ]);

  // Internal dependencies.
  api.use([
    'core',
    'jobs',
    'ui-components'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:classy-test@0.2.26'
  ]);

  api.addFiles([
    'tests.coffee'
   ]);
});
