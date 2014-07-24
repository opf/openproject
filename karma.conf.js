// Karma configuration
// Generated on Sun Apr 06 2014 00:15:29 GMT+0200 (CEST)

module.exports = function(config) {
  config.set({

    // base path that will be used to resolve all patterns (eg. files, exclude)
    basePath: '',

    client: {
      mocha: {
        ui: 'bdd'
      }
    },

    // frameworks to use
    // available frameworks: https://npmjs.org/browse/keyword/karma-adapter
    frameworks: ['mocha', 'chai-sinon'],


    // list of files / patterns to load in the browser
    files: [
      "vendor/assets/components/jquery/dist/jquery.js",
      "vendor/assets/components/angular/angular.js",
      "vendor/assets/components/angular-mocks/angular-mocks.js",
      "vendor/assets/components/angular-ui-select2/src/select2.js",
      "vendor/assets/components/angular-ui-select2/src/select2sortable.js",
      "vendor/assets/components/angular-modal/modal.js",
      "vendor/assets/components/angular-truncate/src/truncate.js",
      "vendor/assets/components/angular-sanitize/angular-sanitize.js",
      "vendor/assets/components/momentjs/moment.js",
      "vendor/assets/components/moment-timezone/moment-timezone.js",
      "vendor/assets/components/angular-context-menu/dist/angular-context-menu.js",
      'vendor/assets/components/select2/select2.js',
      'vendor/assets/components/hyperagent/dist/hyperagent.js',

      "vendor/assets/components/openproject-ui_components/app/assets/javascripts/angular/ui-components-app.js",

      "vendor/assets/javascripts/moment-timezone/moment-timezone-data.js",

      "app/assets/javascripts/angular/openproject-app.js",
      "app/assets/javascripts/angular/config/work-packages-config.js",
      "app/assets/javascripts/angular/config/configuration-service.js",

      "app/assets/javascripts/angular/controllers/**/*.js",
      "app/assets/javascripts/angular/dialogs/**/*.js",
      "app/assets/javascripts/angular/helpers/**/*.js",
      'app/assets/javascripts/angular/filters/**/*.js',
      "app/assets/javascripts/angular/models/**/*.js",
      "app/assets/javascripts/angular/directives/**/*.js",
      'app/assets/javascripts/angular/api/**/*.js',
      'app/assets/javascripts/angular/services/**/*.js',

      "app/assets/javascripts/angular/layout/**/*.js",
      "app/assets/javascripts/angular/work_packages/**/*.js",

      'app/assets/javascripts/autocompleter.js',
      'app/assets/javascripts/members_select_boxes.js',
      'app/assets/javascripts/openproject.js',
      'app/assets/javascripts/timelines_select_boxes.js',

      'app/assets/javascripts/date-en-US.js',

      'karma/tests/timeline_stubs.js',
      'karma/lib/rosie.js',
      'karma/tests/test-helper.js',
      'karma/factories/*factory.js',

      'vendor/assets/components/jquery-mockjax/jquery.mockjax.js',

      'karma/tests/asset_functions.js',
      'karma/tests/**/*test.js',
      'karma/tests/legacy-tests.js',

      'public/templates/**/*.html'
    ],


    // list of files to exclude
    exclude: [

    ],


    // preprocess matching files before serving them to the browser
    // available preprocessors: https://npmjs.org/browse/keyword/karma-preprocessor
    preprocessors: {
      'app/assets/javascripts/*.js': ['coverage'],
      'app/assets/javascripts/angular/**/*.js': ['coverage'],
      'public/templates/**/*.html': ['ng-html2js']
    },


    // test results reporter to use
    // possible values: 'dots', 'progress'
    // available reporters: https://npmjs.org/browse/keyword/karma-reporter
    reporters: ['progress', 'coverage', 'junit'],


    // web server port
    port: 9876,


    // enable / disable colors in the output (reporters and logs)
    colors: true,


    // level of logging
    // possible values: config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
    logLevel: config.LOG_INFO,


    // enable / disable watching file and executing tests whenever any file changes
    autoWatch: true,


    // start these browsers
    // available browser launchers: https://npmjs.org/browse/keyword/karma-launcher
    browsers: ['PhantomJS'],


    // Continuous Integration mode
    // if true, Karma captures browsers, runs the tests and exits
    singleRun: false,



    junitReporter: {
      outputFile: 'karma/reports/test-results.xml'
    },

    coverageReporter: {
      reporters: [
        { type: 'html', dir:'coverage/' },
        { type: 'cobertura' }
      ]
    },

    ngHtml2JsPreprocessor: {
      stripPrefix:  'public',
      moduleName:   'templates'
    }
  });
};
