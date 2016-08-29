Package.describe({
  summary: 'Expressive, dynamic, robust CSS',
  version: "2.513.5"
});

Package.registerBuildPlugin({
  name: 'compileStylusBatch',
  use: ['ecmascript', 'caching-compiler'],
  sources: [
    'plugin/compile-stylus.js'
  ],
  npmDependencies: {
    stylus: "https://github.com/mitar/stylus/tarball/dff4b81ab5c365e3e81536b360263150fd3c47f7", // fork of 0.54.5
    nib: "1.1.2",
    "autoprefixer-stylus": "0.9.4"
  }
});

Package.onUse(function (api) {
  api.use('isobuild:compiler-plugin@1.0.0');
});

Package.onTest(function (api) {
  api.use(['tinytest', 'stylus', 'test-helpers', 'templating']);
  api.addFiles([
    'stylus_tests.html',
    'stylus_tests.styl',
    'stylus_tests.import.styl',
    'stylus_tests.js'
  ],'client');
});
