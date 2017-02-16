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
var fs = require('fs');
var path = require('path');
var _ = require('lodash');
var pathConfig = require('./rails-plugins.conf');
var autoprefixer = require('autoprefixer');

var ExtractTextPlugin = require('extract-text-webpack-plugin');

var mode = (process.env['RAILS_ENV'] || 'production').toLowerCase();
var uglify = (mode !== 'development');

var node_root = path.resolve(__dirname, 'node_modules');


/** Extract available locales from openproject-translations plugin */
var translations = path.resolve(pathConfig.allPluginNamesPaths['openproject-translations'], 'config', 'locales');
var localeIds = ['en'];
fs.readdirSync(translations).forEach(function (file) {
  var matches = file.match( /^js-(.+)\.yml$/);
  if (matches && matches.length > 1) {
    localeIds.push(matches[1]);
  }
});

function getWebpackVendorsConfig() {
  config = {
    entry: {
      vendors: [path.resolve(__dirname, 'app', 'vendors.js')]
    },

    output: {
      path: path.resolve(__dirname, '..', 'app', 'assets', 'javascripts', 'bundles'),
      filename: 'openproject-[name].js',
      library: '[name]'
    },

    resolve: {
      modules: ['node_modules'],
      alias: {
        'at.js': path.resolve(__dirname, 'vendor', 'at.js'),
        'select2': path.resolve(__dirname, 'vendor', 'select2'),
      }
    },

    plugins: [
      new webpack.DllPlugin({
        path: path.join(__dirname, "dist", "[name]-dll-manifest.json"),
        name: "[name]",
        context: '.'
      }),

      // Restrict loaded ngLocale locales to the ones we load from translations
      new webpack.ContextReplacementPlugin(
        /angular\-i18n/,
        new RegExp('angular\-locale\_(' + localeIds.join('|') + ')\.js$', 'i')
      ),

      // Restrict loaded moment locales to the ones we load from translations
      new webpack.ContextReplacementPlugin(/moment[\/\\]locale$/, new RegExp('(' + localeIds.join('|') + ')\.js$', 'i'))
    ]
  };

  if (uglify) {
    console.log("Applying webpack.optimize plugins for production.");
    // Add compression and optimization plugins
    // to the webpack build.
    config.plugins.push(
      new webpack.optimize.UglifyJsPlugin({
        mangle: true,
        compress: true,
        compressor: { warnings: false },
        sourceMap: false,
        exclude: /\.min\.js$/
      }),
      new webpack.LoaderOptionsPlugin({
        // Let loaders know that we're in minification mode
        minimize: true
      })
    );
  }

  return config;
}

module.exports = getWebpackVendorsConfig;
