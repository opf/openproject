// -- copyright
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
// ++

var webpack = require('webpack');
var path = require('path');
var fs = require('fs');
var _ = require('lodash');

var ExtractTextPlugin = require('extract-text-webpack-plugin');
var TextExtractSilencerPlugin = require('./text-extract-silencer.plugin.js');
var TypeScriptDiscruptorPlugin = require('./typescript-disruptor.plugin.js');


var autoprefixer = require('autoprefixer');

var browsersListConfig = fs.readFileSync(path.join(__dirname, '..', '..', 'browserslist'), 'utf8');
var browsersList = _.filter(browsersListConfig.split('\n'), function (entry) {
  return entry && entry.charAt(0) !== '#';
});


function getBaseConfig() {
  var frontendPath = path.resolve(__dirname, '..');
  var opRoot = path.resolve(__dirname, '..', '..');
  var frontendAppPath = path.resolve(frontendPath, 'app');

  var config = {
    // Default root path for entry definitions
    context: frontendAppPath,

    openproject: {
      frontend: frontendPath,
      core: opRoot,
      appPath: frontendAppPath
    },

    // Entry points definitions
    entry: {},

    module: {
      loaders: [
        {
          test: /\.png$/,
          loader: 'url-loader?limit=100000&mimetype=image/png'
        },
        {
          test: /\.gif$/,
          loader: 'file-loader'
        },
        {
          test: /\.jpg$/,
          loader: 'file-loader'
        },
        {
          test: /\.js$/,
          loader: 'ng-annotate?map=false'
        },
        {
          test: /\.ts$/,
          loader: 'ng-annotate!ts-loader'
        },
        {
          test: /\.css$/,
          loader: ExtractTextPlugin.extract(
            'style-loader',
            'css-loader!postcss-loader'
          )
        },
        {
          test: /\.html$/,
          loader: 'ngtemplate?module=openproject.templates&relativeTo=' + frontendAppPath + '!html'
        }
      ],

      // Skip these modules from parsing,
      // We can use it for dependencies that don't rely
      // on other libraries (see vendorized modules)
      noParse: []
    },

    // I18n translations and the library itself is provided by asset pipeline
    externals: {
      "I18n": "I18n"
    },

    resolve: {
      // Root for all our own modules
      root: [ frontendAppPath ],

      // Use aggressive caching
      unsafeCache: true,

      // Extensions to try to resolve require() when
      // not explicitly specified.
      // Do not remove empty option for when requiring with extension.
      extensions: ['', '.webpack.js', '.ts', '.js'],

      // Where to recursively look for dependencies
      // This is pricey, and most paths should be extended
      // in resolve.root instead
      modulesDirectories: [
        'node_modules',
        path.join(frontendPath, 'node_modules')
      ],

      alias: {
        'core-frontend': frontendPath,
        'core-components': path.join(frontendAppPath, 'components'),
        'angular-truncate': 'angular-truncate/src/truncate',
        'angular-context-menu': 'angular-context-menu/dist/angular-context-menu.js',
        'mousetrap': 'mousetrap/mousetrap.js',
        'hyperagent': 'hyperagent/dist/hyperagent',
      }
    },

    // Where to resolve loaders
    // We only use npm loader modules
    resolveLoader: {
      root: path.join(frontendPath, 'node_modules')
    },

    // Expose TypeScript configuration
    // so that typings is available to other modules (e.g., plugins)
    ts: {
      configFileName: path.join(frontendPath, 'tsconfig.json')
    },

    // Reduce logging
    stats: {
      hash: false,
      version: false,
      timings: true,
      assets: false,
      chunks: false,
      modules: false,
      reasons: true,
      children: true,
      source: false,
      errors: true,
      errorDetails: true,
      warnings: true,
      publicPath: false
    },

    // CSS postprocessing (autoprefixer)
    postcss: [
      autoprefixer({ browsers: browsersList, cascade: false })
    ],

    plugins: [
      // Add a simple fail plugin to return a status code of 2 if
      // errors are detected (this includes TS warnings)
      // It is ONLY executed when `ENV[CI]` is set or `--bail` is used.
      TypeScriptDiscruptorPlugin,
      // Global variables provided in all entries
      // We should avoid this since it reduces webpack
      // strengths to discover dependency use.
      new webpack.ProvidePlugin({
        'URI': 'URIjs',
        'Rx': 'rxjs',
        'URITemplate': 'URIjs/src/URITemplate'
      }),
      new ExtractTextPlugin('openproject-[name].css'),
      new TextExtractSilencerPlugin()
    ]
  };

  var vendorize = [
    {
      alias: 'angular-animate',
      path: 'angular-animate/angular-animate.min.js'
    },
    {
      alias: 'angular-modal',
      path: 'angular-modal/modal.min.js'
    },
    {
      alias: 'angular-ui-router',
      path: 'angular-ui-router/build/angular-ui-router.min.js'
    },
    {
      alias: 'at.js',
      path: 'at.js/dist/'
    },
    {
      alias: 'jquery',
      path: 'jquery/dist/jquery.min.js',
      parse: true
    },
    {
      alias: 'jquery-caret',
      path: 'jquery-caret/jquery.caret.js'
    },
    {
      alias: 'moment-timezone',
      path: 'moment-timezone/builds/moment-timezone-with-data.min.js',
      parse: true
    },
    {
      alias: 'ngFileUpload',
      path: 'ng-file-upload/dist/ng-file-upload.min.js'
    },
    {
      alias: 'restangular',
      path: 'restangular/dist/restangular.min.js',
      parse: true
    },
    {
      alias: 'rxjs',
      path: 'rx-lite/rx.lite.min.js',
      parse: true
    }
  ];

  vendorize.forEach(function (entry) {
    var fullPath = path.resolve(__dirname, '..', 'node_modules', entry.path);
    if (entry.alias) {
      config.resolve.alias[entry.alias] = fullPath;
    }

    if (!entry.parse) {
      config.module.noParse.push(fullPath);
    }
  });

  return config;
}

module.exports = getBaseConfig;
