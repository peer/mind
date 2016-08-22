Package.describe({
  name: 'sanitize',
  version: '0.1.0'
});

Package.onUse(function (api) {
  api.versionsFrom('1.4.1');

  // Core dependencies.
  api.use([
    'coffeescript',
    'jquery'
  ]);

  // 3rd party dependencies.
  api.use([
    'fermuch:cheerio@0.19.0',
    'peerlibrary:assert@0.2.5',
    'peerlibrary:url-utils@0.4.0_3'
  ]);

  // Internal dependencies.
  api.use([
    'underscore-extra'
  ]);

  api.export('Sanitize');

  api.addFiles([
    'sanitize.coffee'
  ]);
});

Package.onTest(function (api) {
  api.versionsFrom('1.4.1');

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
    'peerlibrary:classy-test@0.2.26'
  ]);

  api.addFiles([
    'tests.coffee'
   ]);
});
