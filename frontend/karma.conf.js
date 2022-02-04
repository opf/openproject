// Karma configuration file, see link for more information
// https://karma-runner.github.io/1.0/config/configuration-file.html

module.exports = function (config) {
  config.set({
    basePath: '',
    files: [
      // I18n.js is provided by the Asset pipeline,
      // which is unavailable for unit tests.
      // For testing, shim its functionality
      'src/test/i18n-shim.ts',
      'node_modules/jquery/dist/jquery.js',
      // 'node_modules/angular-mocks/angular-mocks.js'
    ],
    frameworks: ['jasmine', '@angular-devkit/build-angular'],
    plugins: [
      require('karma-jasmine'),
      require('karma-chrome-launcher'),
      require('@angular-devkit/build-angular/plugins/karma'),
      require('karma-spec-reporter'),
    ],
    client:{
      clearContext: false // leave Jasmine Spec Runner output visible in browser
    },
    coverageIstanbulReporter: {
      dir: require('path').join(__dirname, 'coverage'), reports: [ 'html', 'lcovonly' ],
      fixWebpackSourcePaths: true
    },
    angularCli: {
      environment: 'dev'
    },
    reporters: ['spec'],
    specReporter: {
      maxLogLines: 5,         // limit number of lines logged per test
      suppressErrorSummary: false,  // do not print error summary
      suppressFailed: false,  // do not print information about failed tests
      suppressPassed: false,  // do not print information about passed tests
      suppressSkipped: true,  // do not print information about skipped tests
      showSpecTiming: true, // print the time elapsed for each spec
      failFast: false,
    },
    port: 9876,
    colors: true,
    failOnEmptyTestSuite: true,
    logLevel: config.LOG_INFO,
    autoWatch: true,
    browsers: ['ChromeHeadlessNoSandbox'],
    customLaunchers: {
      ChromeHeadlessNoSandbox: {
        base: 'ChromeHeadless',
        flags: ['--no-sandbox']
      },
      ChromeWithDebug: {
        base: 'Chrome',
        flags: ['--no-sandbox', '--debug', '--auto-open-devtools-for-tabs']
      }
    },
    singleRun: false
  });
};
