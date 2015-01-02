//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
      'app/global.js',
      'app/openproject-app.js',
      "bower_components/angular-mocks/angular-mocks.js",

      "../app/assets/javascripts/lib/jquery.trap.js",

      '../app/assets/javascripts/autocompleter.js',
      '../app/assets/javascripts/members_select_boxes.js',
      '../app/assets/javascripts/openproject.js',
      '../app/assets/javascripts/timelines_select_boxes.js',
      '../app/assets/javascripts/jstoolbar/jstoolbar.js',

      '../app/assets/javascripts/date-en-US.js',

      'tests/unit/tests/timeline_stubs.js',
      'tests/unit/lib/rosie.js',
      'tests/unit/tests/test-helper.js',
      'tests/unit/factories/*factory.js',

      'bower_components/jquery-mockjax/jquery.mockjax.js',

      'tests/unit/tests/asset_functions.js',
      'tests/unit/tests/**/*test.js',
      'tests/unit/tests/legacy-tests.js'
    ],


    // list of files to exclude
    exclude: [

    ],


    // preprocess matching files before serving them to the browser
    // available preprocessors: https://npmjs.org/browse/keyword/karma-preprocessor
    preprocessors: {
      '../app/assets/javascripts/*.js': ['coverage'],
      'app/**/*.js': ['webpack'] // coverage disabled
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
      outputFile: 'tests/unit/reports/test-results.xml'
    },

    coverageReporter: {
      reporters: [
        { type: 'html', dir:'coverage/' },
        { type: 'cobertura' }
      ]
    },

    webpack: require('./webpack.config.js'),

    webpackServer: {
      noInfo: true
    }
  });
};
