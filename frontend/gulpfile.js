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

var path = require('path');
var gulp = require('gulp');
var jshint = require('gulp-jshint');
var gulpWebpack = require('gulp-webpack');
var webpack = require('webpack');
var config = require('./webpack.config.js');
var sass = require('gulp-ruby-sass');
var watch = require('gulp-watch');
var autoprefixer = require('gulp-autoprefixer');
var livingstyleguide = require('gulp-livingstyleguide');
var gulpFilter = require('gulp-filter');
var replace = require('gulp-replace');
var tsproject = require('tsproject');
var karma = require('karma');
var fs = require('fs');

var protractor = require('gulp-protractor').protractor,
  webdriverStandalone = require('gulp-protractor').webdriver_standalone,
  webdriverUpdate = require('gulp-protractor').webdriver_update;

var server;

var paths = {
  scripts: [
    'app/**/*.js',
    '!app/vendor/**/*.js'
  ],
  fonts: '../app/assets/fonts/**/*',
  styleguide: '../app/assets/stylesheets/styleguide.html.lsg'
};

var deleteFolderRecursive = function(path) {
  if( fs.existsSync(path) ) {
    fs.readdirSync(path).forEach(function(file){
      var curPath = path + "/" + file;

      if(fs.lstatSync(curPath).isDirectory()) {
        deleteFolderRecursive(curPath);

      } else {
        fs.unlinkSync(curPath);
      }
    });

    fs.rmdirSync(path);
  }
};

gulp.task('lint', function() {
  return gulp.src(paths.scripts)
    .pipe(jshint('.jshintrc'))
    .pipe(jshint.reporter('jshint-stylish'));
});

gulp.task('webpack', function() {
  return gulp.src('app/openproject-app.js')
    .pipe(gulpWebpack(config))
    .pipe(gulp.dest('../app/assets/javascripts/bundles'));
});

gulp.task('fonts', function() {
  return gulp.src(paths.fonts).pipe(gulp.dest('./public/assets/css'));
});

gulp.task('sass', function() {
  return gulp.src('../app/assets/stylesheets/default.css.sass')
    .pipe(sass({
      'sourcemap=none': true,
      bundleExec: true,
      loadPath: [
        './bower_components/foundation-apps/scss',
        './bower_components/bourbon/app/assets/stylesheets'
      ]
    }))
    // HACK: remove asset helper that is only available with asset pipeline
    .pipe(replace(/image\-url\(\"/g, 'url("/assets/'))
    .pipe(autoprefixer({
      cascade: false
    }))
    .on('error', function(err) {
      console.log(err.message);
    })
    .pipe(gulp.dest('public/assets/css'));
});

gulp.task('styleguide', function () {
  process.env.SASS_PATH = [
    '../app/assets/stylesheets',
    './bower_components/foundation-apps/scss',
    './bower_components/bourbon/app/assets/stylesheets'
  ].join(':');

  var cssFilter = gulpFilter('**/*.css'),
      htmlFilter = gulpFilter('**/*.html');

  gulp.src(paths.styleguide)
    .pipe(livingstyleguide({template: 'app/assets/styleguide.jade'}))
    .pipe(cssFilter)
    .pipe(replace(/image\-url\(\"/g, 'url("/assets/'))
    .pipe(autoprefixer({
      cascade: false
    }))
    .pipe(cssFilter.restore())
    .pipe(htmlFilter)
    .pipe(replace(/STYLEGUIDE_HTML_ID/,
      path.dirname(path.resolve(paths.styleguide)) + '/styleguide')
    )
    .pipe(htmlFilter.restore())
    .pipe(gulp.dest('public/assets/css'));
  });

gulp.task('express', function(done) {
  var expressApp = require('./server');
  var port = process.env.PORT || 8080;

  (function startServer(port) {
    server = expressApp.listen(port, function() {
      console.log('Starting express server at localhost:%d', port);
      done();
    });

    server.on('error', function(err) {
      if (err.code === 'EADDRINUSE') {
        console.warn('Port %d already in use.', port);
        startServer(++port);
      }
    });
  })(port);
});

gulp.task('webdriver:update', webdriverUpdate);
gulp.task('webdriver:standalone', ['webdriver:update'], webdriverStandalone);

gulp.task('tests:protractor', ['webdriver:update', 'webpack', 'sass', 'express'], function(done) {
  var address = server.address().address;
  if (server.address().family === 'IPv6') {
    address = '[' + address + ']';
  }
  gulp.src('tests/integration/**/*_spec.js')
    .pipe(protractor({
      configFile: 'tests/integration/protractor.conf.js',
      args: ['--baseUrl', 'http://' + address + ':' + server.address().port]
    }))
    .on('error', function(e) {
      throw e;
    })
    .on('end', function() {
      server.close();
      done();
    });
});

gulp.task('default', ['webpack', 'fonts', 'styleguide', 'sass', 'express']);
gulp.task('dev', ['default', 'watch']);
gulp.task('watch', function() {
  gulp.watch('app/**/*.js', ['webpack']);
  gulp.watch('app/**/*.html', ['webpack']);
  gulp.watch('config/locales/js-*.yml', ['webpack']);
  gulp.watch('app/templates/**/*.html', ['webpack']);

  gulp.watch('../app/assets/stylesheets/**/*.scss', ['sass', 'styleguide']);
  gulp.watch('../app/assets/stylesheets/**/*.sass', ['sass', 'styleguide']);
  gulp.watch('../app/assets/stylesheets/**/*.lsg',  ['styleguide']);
});


var tsOutDir = __dirname + '/tests/unit/tests/typescript';

gulp.task('typescript-tests', function () {
  deleteFolderRecursive(tsOutDir);

  return tsproject.src('./tsconfig.test.json', {
    compilerOptions: {
      outDir: tsOutDir
    }
  }).pipe(gulp.dest('.'));
});

gulp.task('tests:karma', ['typescript-tests'], function () {
  karma.server.start(
    {
      configFile: __dirname + '/karma.conf.js',
      singleRun: true
    },
    function (exitCode) {
      if(exitCode === 0) {
        console.info('No tests have failed');
        console.info('Files generated by tsc were deleted.');
        deleteFolderRecursive(tsOutDir);
      }
      else {
        console.warn('Tests have failed');
        console.info('Files generated by tsc can be found in: ' + tsOutDir);
      }

      process.exit(exitCode);
    }
  );
});
