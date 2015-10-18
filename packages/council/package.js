Package.describe({
  name: 'council',
  version: '0.1.0'
});

Package.onUse(function (api) {
  api.versionsFrom('1.0.3.1');

  // Core dependencies.
  api.use([
    'coffeescript',
    'underscore',
    'accounts-password',
    'accounts-ui'
  ]);

  // 3rd party dependencies.
  api.use([
    'kadira:flow-router@2.7.0',
    'kadira:blaze-layout@2.2.0',
    'peerlibrary:computed-field@0.3.0',
    'peerlibrary:assert@0.2.5'
  ]);

  // Internal dependencies.
  api.use([
    'core',
    'api',
    'ui-components'
  ]);

  api.addFiles([
    'accounts/config.coffee',
    'flow-router/root.html',
    'flow-router/root.coffee',
    'flow-router/layout.html',
    'flow-router/layout.coffee',
    'flow-router/header.html',
    'flow-router/header.coffee',
    'flow-router/not-found.html',
    'flow-router/not-found.coffee',
    'discussion/list.html',
    'discussion/list.coffee',
    'discussion/new.html',
    'discussion/new.coffee'
  ], 'client');
});
