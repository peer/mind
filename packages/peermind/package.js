Package.describe({
  name: 'peermind',
  version: '0.1.0'
});

var options = {
  autoprefixer: {
    browsers: ['last 3 Chrome versions', 'Firefox >= 7', 'Explorer >= 8', 'last 2 versions', '> 1%', 'Firefox ESR', 'Safari >= 4']
  }
};

Package.onUse(function (api) {
  api.versionsFrom('1.4.1');

  // Core dependencies.
  api.use([
    'coffeescript',
    'accounts-password',
    'accounts-facebook',
    'accounts-google',
    'accounts-twitter',
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
    'peerlibrary:computed-field@0.6.0',
    'peerlibrary:reactive-field@0.3.0',
    'peerlibrary:assert@0.2.5',
    'materialize:materialize@0.97.7',
    'useraccounts:materialize@1.14.2',
    'useraccounts:flow-routing@1.14.2',
    'velocityjs:velocityjs@1.2.1',
    'mfpierre:chartist-js@1.6.2',
    'cunneen:accounts-admin-materializecss@0.3.0',
    'peerlibrary:blaze-layout-component@0.2.0',
    'momentjs:moment@2.15.0',
    'mizzao:jquery-ui@1.11.4',
    'fourseven:scss@3.9.0',
    'softwarerero:accounts-t9n@1.3.3',
    'doctorpangloss:method-hooks@2.0.2',
    'peerlibrary:subscription-scope@0.1.0'
  ]);

  // Internal dependencies.
  api.use([
    'underscore-extra',
    'core',
    'api',
    'ui-components',
    'trix',
    'storage',
    'loading',
    'jquery-ui-touch-punch',
    'scroll-lock'
  ]);

  api.addFiles([
    'account/config.coffee',
    'account/form.html',
    'account/form.coffee',
    'account/form.styl',
    'account/templates.coffee'
  ], ['client', 'server'], options);

  api.addFiles([
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
    'base/isseen.coffee',
    'base/infinite-scrolling.coffee',
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
    'layout/mobile.html',
    'discussion/base.coffee',
    'discussion/list.html',
    'discussion/list.coffee',
    'discussion/list.styl',
    'discussion/new.html',
    'discussion/new.coffee',
    'discussion/display.html',
    'discussion/display.coffee',
    'discussion/display.styl',
    'discussion/close.html',
    'discussion/close.coffee',
    'discussion/close.styl',
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
    'meeting/display.html',
    'meeting/display.coffee',
    'meeting/display.styl',
    'meeting/discussions.html',
    'meeting/discussions.coffee',
    'meeting/discussions.styl',
    'motion/list.html',
    'motion/list.coffee',
    'motion/list.styl',
    'motion/new.html',
    'motion/new.coffee',
    'motion/vote.html',
    'motion/vote.coffee',
    'motion/vote.styl',
    'admin/accounts.html',
    'admin/accounts.coffee',
    'user/display.html',
    'user/display.coffee',
    'user/display.styl',
    'activity/list.html',
    'activity/list.coffee',
    'activity/list.styl'
  ], 'client', options);

  api.addAssets([
    'layout/logo.svg'
  ], 'client');
});
