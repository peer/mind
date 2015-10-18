Package.describe({
  name: 'ui-components',
  version: '0.1.0'
});

Package.onUse(function (api) {
  api.versionsFrom('1.0.3.1');

  // Core dependencies.
  api.use([
    'coffeescript'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:blaze-components@0.13.0'
  ]);

  // Internal dependencies.
  api.use([
  ]);

  api.imply([
    'templating'
  ]);

  api.export('UIComponent');

  api.addFiles([
    'base.coffee'
  ]);
});
