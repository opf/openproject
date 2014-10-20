//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

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
      "vendor/assets/components/lodash/dist/lodash.js",
      "vendor/assets/components/angular/angular.js",
      "vendor/assets/components/angular-mocks/angular-mocks.js",
      "vendor/assets/components/angular-ui-router/release/angular-ui-router.js",
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

      "app/assets/javascripts/angular/config/configuration-service.js",
      'app/assets/javascripts/angular/api/**/*.js',
      "app/assets/javascripts/angular/helpers/**/*.js",
      "app/assets/javascripts/angular/models/**/*.js",
      'app/assets/javascripts/angular/services/**/*.js',

      "app/assets/javascripts/angular/layout/**/*.js",
      "app/assets/javascripts/angular/messages/**/*.js",
      "app/assets/javascripts/angular/time_entries/**/*.js",
      "app/assets/javascripts/angular/timelines/**/*.js",
      "app/assets/javascripts/angular/ui_components/**/*.js",
      "app/assets/javascripts/angular/work_packages/**/*.js",

      "app/assets/javascripts/lib/jquery.trap.js",

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
