Package.describe({
  name: 'ui-components',
  version: '0.1.0'
});

Package.onUse(function (api) {
  api.versionsFrom('1.2.0.2');

  // Core dependencies.
  api.use([
    'coffeescript',
    'underscore-extra',
    'spacebars',
    'tracker'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:blaze-components@0.15.0',
    'kadira:flow-router@2.7.0',
    'momentjs:moment@2.10.6',
    'peerlibrary:assert@0.2.5'
  ]);

  // Internal dependencies.
  api.use([
  ]);

  api.imply([
    'templating'
  ]);

  api.export('UIComponent');
  api.export('UIMixin');

  api.addFiles([
    'base.coffee'
  ]);
});
