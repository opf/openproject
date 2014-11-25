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

var gulp = require('gulp');
var jshint = require('gulp-jshint');
var gulpWebpack = require('gulp-webpack');
var webpack = require('webpack');
var config = require('./webpack.config.js');
var sass = require('gulp-ruby-sass');
var watch = require('gulp-watch');
var uglify = require('gulp-uglify');
var concat = require('gulp-concat');
var ngAnnotate = require('gulp-ng-annotate');
var templateCache = require('gulp-angular-templatecache');
var protractor = require('gulp-protractor').protractor,
  webdriverStandalone = require('gulp-protractor').webdriver_standalone,
  webdriverUpdate = require('gulp-protractor').webdriver_update;

var server;

var paths = {
  scripts: [
    'frontend/app/**/*.js',
    '!frontend/app/vendor/**/*.js'
  ]
};

gulp.task('lint', function() {
  return gulp.src(paths.scripts)
    .pipe(jshint('.jshintrc'))
    .pipe(jshint.reporter('jshint-stylish'));
});

gulp.task('webpack', function() {
  return gulp.src('frontend/app/openproject-app.js')
    .pipe(gulpWebpack(config))
    .pipe(gulp.dest('app/assets/javascripts/bundles'));
});

gulp.task('minify', function() {
  return gulp.src('frontend/app/openproject-app.js')
    .pipe(gulpWebpack(config))
    .pipe(ngAnnotate())
    .pipe(uglify())
    .pipe(gulp.dest('app/assets/javascripts/bundles'));
});

gulp.task('templates', function () {
  return gulp.src('public/templates/**/*.html')
    .pipe(templateCache({
      standalone: false,
      module: 'openproject.templates',
      root: '/templates'
    }))
    .pipe(gulp.dest('tmp'));
});

gulp.task('sass', function() {
  return gulp.src('app/assets/stylesheets/default.css.sass')
    .pipe(sass({
      bundleExec: true,
      require: 'bourbon'
    }))
    .on('error', function(err) {
      console.log(err.message);
    })
    .pipe(gulp.dest('tmp/stylesheets'));
});

gulp.task('express', function() {
  var expressApp = require('./frontend/tests/integration/server');
  var port = process.env.PORT || 8080;

  (function startServer(port) {
    server = expressApp.listen(port, function() {
      console.log('Starting express server at localhost:%d', port);
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

function protractorFunc(done) {
  gulp.src('frontend/tests/integration/**/*_spec.js')
    .pipe(protractor({
      configFile: 'frontend/tests/integration/protractor.conf.js',
      args: ['--baseUrl', 'http://' + server.address().address + ':' + server.address().port]
    }))
    .on('error', function(e) {
      throw e;
    })
    .on('end', function() {
      server.close();
      done();
    });
}

gulp.task('tests:protractor', ['webdriver:update', 'webpack', 'sass', 'express'], protractorFunc);
gulp.task('tests:protractor:minified', ['webdriver:update', 'production', 'express'], protractorFunc);

gulp.task('default', ['webpack', 'sass', 'express', 'watch']);
gulp.task('production', ['sass', 'minify', 'templates'], function() {
  return gulp.src(['app/assets/javascripts/bundles/openproject-app.js', 'tmp/templates.js'])
    .pipe(concat('openproject-app.js'))
    .pipe(gulp.dest('app/assets/javascripts/bundles'));
});
gulp.task('watch', function() {
  gulp.watch('frontend/app/**/*.js', ['webpack']);
  gulp.watch('config/locales/js-*.yml', ['webpack']);
  gulp.watch('app/assets/stylesheets/**/*.sass', ['sass']);
});
