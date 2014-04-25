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
      "vendor/assets/components/jquery/jquery.js",
      "vendor/assets/components/angular/angular.js",
      "vendor/assets/components/angular-mocks/angular-mocks.js",
      "vendor/assets/components/angular-ui-select2/src/select2.js",

      "vendor/assets/components/openproject-ui_components/app/assets/javascripts/angular/ui-components-app.js",
      "app/assets/javascripts/angular/openproject-app.js",
      "app/assets/javascripts/angular/helpers/components/i18n.js",
      "app/assets/javascripts/angular/config/work-packages-config.js",

      "app/assets/javascripts/angular/helpers/components/custom-field-helper.js",
      'app/assets/javascripts/angular/helpers/components/path-helper.js',
      'app/assets/javascripts/angular/helpers/filters-helper.js',
      'app/assets/javascripts/angular/helpers/components/work-packages-helper.js',
      'app/assets/javascripts/angular/helpers/work-packages-table-helper.js',
      'app/assets/javascripts/angular/helpers/function-decorators.js',

      'app/assets/javascripts/angular/filters/work-packages-filters.js',

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
      "app/assets/javascripts/angular/directives/components/*.js",

      'app/assets/javascripts/angular/services/status-service.js',
      'app/assets/javascripts/angular/services/type-service.js',
      'app/assets/javascripts/angular/services/priority-service.js',
      'app/assets/javascripts/angular/services/user-service.js',
      'app/assets/javascripts/angular/services/version-service.js',
      'app/assets/javascripts/angular/services/role-service.js',
      'app/assets/javascripts/angular/services/group-service.js',
      'app/assets/javascripts/angular/services/pagination-service.js',
      'app/assets/javascripts/angular/services/project-service.js',
      'app/assets/javascripts/angular/services/work-package-service.js',
      'app/assets/javascripts/angular/services/query-service.js',
      'app/assets/javascripts/angular/services/pagination-service.js',

      "app/assets/javascripts/angular/directives/work_packages/*.js",
      "app/assets/javascripts/angular/directives/timelines/*.js",

      "app/assets/javascripts/angular/controllers/timelines-controller.js",
      "app/assets/javascripts/angular/controllers/work-packages-controller.js",


      'app/assets/javascripts/date-en-US.js',

      'karma/tests/timeline_stubs.js',
      'karma/lib/rosie.js',
      'karma/tests/test-helper.js',
      'karma/factories/*factory.js',

      'karma/tests/asset_functions.js',
      'karma/tests/**/*test.js',

      'public/templates/**/*.html'
    ],


    // list of files to exclude
    exclude: [

    ],


    // preprocess matching files before serving them to the browser
    // available preprocessors: https://npmjs.org/browse/keyword/karma-preprocessor
    preprocessors: {
      'public/templates/**/*.html': ['ng-html2js']
    },


    // test results reporter to use
    // possible values: 'dots', 'progress'
    // available reporters: https://npmjs.org/browse/keyword/karma-reporter
    reporters: ['progress', 'junit'],


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

    ngHtml2JsPreprocessor: {
      stripPrefix:  'public',
      moduleName:   'templates'
    }
  });
};
