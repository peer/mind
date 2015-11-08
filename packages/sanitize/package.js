Package.describe({
  name: 'sanitize',
  version: '0.1.0'
});

Package.onUse(function (api) {
  api.versionsFrom('1.2.0.2');

  // Core dependencies.
  api.use([
    'coffeescript',
    'underscore-extra',
    'jquery'
  ]);

  // 3rd party dependencies.
  api.use([
    'fermuch:cheerio@0.19.0',
    'peerlibrary:assert@0.2.5',
    'peerlibrary:url-utils@0.4.0_3'
  ]);

  api.export('Sanitize');

  api.addFiles([
    'sanitize.coffee'
  ]);
});

Package.onTest(function (api) {
  // Core dependencies.
  api.use([
    'coffeescript'
  ]);

  // Internal dependencies.
  api.use([
    'sanitize'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:classy-test@0.2.20'
  ]);

  api.addFiles([
    'tests.coffee'
   ]);
});
