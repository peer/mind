Package.describe({
  name: 'sanitize',
  version: '0.1.0'
});

Package.onUse(function (api) {
  api.versionsFrom('1.2.0.2');

  // Core dependencies.
  api.use([
    'coffeescript'
  ]);

  // 3rd party dependencies.
  api.use([
    'fermuch:cheerio@0.19.0',
    'peerlibrary:assert@0.2.5',
    'peerlibrary:url-utils@0.4.0_2'
  ]);

  // Internal dependencies.
  api.use([
    'core'
  ]);

  api.export('Sanitize');

  api.addFiles([
    'sanitize.coffee'
  ], 'server');
});
