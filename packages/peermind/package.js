Package.describe({
  name: 'peermind',
  version: '0.1.0'
});

Package.onUse(function (api) {
  api.versionsFrom('1.4.1');

  // Core dependencies.
  api.use([
    'coffeescript',
    'accounts-password',
    'accounts-facebook',
    'service-configuration',
    'stylus',
    'jquery',
    'random',
    'ejson',
    'tracker',
    'webapp'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:flow-router@2.12.1_1',
    'kadira:blaze-layout@2.3.0',
    'peerlibrary:computed-field@0.3.1',
    'peerlibrary:reactive-field@0.1.0',
    'peerlibrary:assert@0.2.5',
    'materialize:materialize@0.97.7',
    'useraccounts:materialize@1.14.2',
    'useraccounts:flow-routing@1.14.2',
    'velocityjs:velocityjs@1.2.1',
    'mfpierre:chartist-js@1.6.2',
    'cunneen:accounts-admin-materializecss@0.3.0',
    'peerlibrary:blaze-layout-component@0.1.1',
    'momentjs:moment@2.14.4',
    'mizzao:jquery-ui@1.11.4',
    'fourseven:scss@3.8.0_1'
  ]);

  // Internal dependencies.
  api.use([
    'underscore-extra',
    'core',
    'api',
    'ui-components',
    'trix',
    'storage'
  ]);

  api.addFiles([
    'account/config.coffee'
  ]);

  api.addFiles([
    'account/templates.coffee',
    'account/services.coffee'
  ], 'server');

  api.addFiles([
    'base/colors.styl',
    'base/variables.styl',
    'base/base.styl'
  ], 'client', {isImport: true});

  api.addFiles([
    'base/base.scss',
    'base/upvoteable.html',
    'base/upvoteable.coffee',
    'base/upvoteable.styl',
    'base/expandable.html',
    'base/expandable.coffee',
    'base/expandable.styl',
    'base/editable.html',
    'base/editable.coffee',
    'base/editable.styl',
    'base/metadata.html',
    'base/metadata.coffee',
    'base/metadata.styl',
    'base/editor.html',
    'base/editor.coffee',
    'base/editor.styl',
    'account/form.coffee',
    'account/settings.html',
    'account/settings.coffee',
    'account/settings.styl',
    'layout/title.coffee',
    'layout/layout.html',
    'layout/layout.coffee',
    'layout/layout.styl',
    'layout/header.html',
    'layout/header.coffee',
    'layout/header.styl',
    'layout/footer.html',
    'layout/footer.coffee',
    'layout/not-found.html',
    'layout/not-found.coffee',
    'layout/access-denied.html',
    'layout/access-denied.coffee',
    'layout/icons.html',
    'layout/sandstorm.coffee',
    'discussion/base.coffee',
    'discussion/list.html',
    'discussion/list.coffee',
    'discussion/new.html',
    'discussion/new.coffee',
    'discussion/edit.html',
    'discussion/edit.coffee',
    'discussion/display.html',
    'discussion/display.coffee',
    'comment/list.html',
    'comment/list.coffee',
    'comment/list.styl',
    'comment/new.html',
    'comment/new.coffee',
    'point/list.html',
    'point/list.coffee',
    'point/list.styl',
    'point/new.html',
    'point/new.coffee',
    'point/new.styl',
    'meeting/base.coffee',
    'meeting/list.html',
    'meeting/list.coffee',
    'meeting/new.html',
    'meeting/new.coffee',
    'meeting/edit.html',
    'meeting/edit.coffee',
    'meeting/display.html',
    'meeting/display.coffee',
    'motion/list.html',
    'motion/list.coffee',
    'motion/list.styl',
    'motion/new.html',
    'motion/new.coffee',
    'motion/vote.html',
    'motion/vote.coffee',
    'motion/vote.styl',
    'admin/accounts.html',
    'admin/accounts.coffee'
  ], 'client');

  api.addAssets([
    'layout/logo.svg'
  ], 'client');
});
