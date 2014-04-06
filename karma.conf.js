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
    frameworks: ['mocha', 'chai'],


    // list of files / patterns to load in the browser
    files: [
      "vendor/assets/components/jquery/jquery.js",
      "vendor/assets/components/angular/angular.js",
      "vendor/assets/components/angular-mocks/angular-mocks.js",
      "vendor/assets/components/angular-ui-select2/src/select2.js",

      "vendor/assets/components/openproject-ui_components/app/assets/javascripts/angular/ui-components-app.js",
      "app/assets/javascripts/angular/openproject-app.js",
      "app/assets/javascripts/angular/controllers/timelines_controller.js",
      "app/assets/javascripts/angular/helpers/components/i18n.js",
      "app/assets/javascripts/angular/helpers/components/custom-field-helper.js",
      "app/assets/javascripts/angular/config/work-packages-config.js",
      "app/assets/javascripts/angular/models/filter.js",
      "app/assets/javascripts/angular/models/query.js",
      "app/assets/javascripts/angular/models/sortation.js",
      "app/assets/javascripts/angular/models/timelines/color.js",
      "app/assets/javascripts/angular/models/timelines/custom-field.js",
      "app/assets/javascripts/angular/models/timelines/timeline.js",
      "app/assets/javascripts/angular/models/timelines/color.js",
      "app/assets/javascripts/angular/models/timelines/custom-field.js",
      "app/assets/javascripts/angular/models/timelines/historical_planning_element.js",
      "app/assets/javascripts/angular/models/timelines/mixins/constants.js",
      "app/assets/javascripts/angular/models/timelines/mixins/ui.js",
      "app/assets/javascripts/angular/models/timelines/planning_element.js",
      "app/assets/javascripts/angular/models/timelines/planning_element_type.js",
      "app/assets/javascripts/angular/models/timelines/project.js",
      "app/assets/javascripts/angular/models/timelines/project_association.js",
      "app/assets/javascripts/angular/models/timelines/project_type.js",
      "app/assets/javascripts/angular/models/timelines/reporting.js",
      "app/assets/javascripts/angular/models/timelines/status.js",
      "app/assets/javascripts/angular/models/timelines/tree_node.js",
      "app/assets/javascripts/angular/models/timelines/user.js",

      'app/assets/javascripts/date-en-US.js',

      'mocha/tests/timeline_stubs.js',
      'mocha/lib/rosie.js',
      'mocha/tests/test-helper.js',
      'mocha/factories/*factory.js',

      'mocha/tests/asset_functions.js',
      'mocha/tests/**/*test.js'
    ],


    // list of files to exclude
    exclude: [

    ],


    // preprocess matching files before serving them to the browser
    // available preprocessors: https://npmjs.org/browse/keyword/karma-preprocessor
    preprocessors: {

    },


    // test results reporter to use
    // possible values: 'dots', 'progress'
    // available reporters: https://npmjs.org/browse/keyword/karma-reporter
    reporters: ['progress'],


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
    singleRun: false
  });
};
