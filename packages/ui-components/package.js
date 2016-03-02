Package.describe({
  name: 'ui-components',
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
    'peerlibrary:blaze-components@0.16.2',
    'peerlibrary:blaze-common-component@0.1.0'
  ]);

  // Internal dependencies.
  api.use([
    'storage'
  ]);

  api.imply([
    'peerlibrary:blaze-components'
  ]);

  api.export('UIComponent');
  api.export('UIMixin');

  api.addFiles([
    'base.coffee'
  ]);
});
