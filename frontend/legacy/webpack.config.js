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

var CleanWebpackPlugin = require('clean-webpack-plugin');
var MiniCssExtractPlugin = require('mini-css-extract-plugin');
var UglifyJsPlugin = require('uglifyjs-webpack-plugin');
// var BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin;

var mode = (process.env['RAILS_ENV'] || 'production').toLowerCase();
var production = (mode !== 'development');
var debug_output = (!production || !!process.env['OP_FRONTEND_DEBUG_OUTPUT']);

var node_root = path.resolve(__dirname, '..', 'node_modules');
var output_root = path.resolve(__dirname, '..', '..', 'app', 'assets', 'javascripts');
var bundle_output = path.resolve(output_root, 'bundles');

var pluginEntries = _.reduce(pathConfig.pluginNamesPaths, function (entries, pluginPath, name) {
  entries[name.replace(/^openproject\-/, '')] = path.resolve(pluginPath, 'frontend', 'app', name + '-app.js');
  return entries;
}, {});

var pluginAliases = _.reduce(pathConfig.pluginNamesPaths, function (entries, pluginPath, name) {
  entries[name] = path.basename(pluginPath);
  return entries;
}, {});

var loaders = [
  {
    test: /\.tsx?$/,
    include: [
      path.resolve(__dirname, '..', 'common'),
      path.resolve(__dirname, 'app'),
      path.resolve(__dirname, 'tests')
    ].concat(_.values(pathConfig.pluginNamesPaths)),
    use: [
      {
        loader: 'ts-loader',
        options: {
          logLevel: 'info',
          configFile: path.resolve(__dirname, 'tsconfig.json')
        }
      }
    ]
  },
  {
    test: /\.css$/,
    use: [
      MiniCssExtractPlugin.loader,
      'css-loader',
      'postcss-loader'
    ]
  },
  {
    test: /\.png$/,
    use: [
      {
        loader: 'url-loader',
        options: {
          limit: '100000',
          mimetype: 'image/png'
        }
      }
    ]
  },
  {
    test: /\.gif$/,
    use: ['file-loader']
  },
  {
    test: /\.jpg$/,
    use: ['file-loader']
  },
];

for (var k in pathConfig.pluginNamesPaths) {
  if (pathConfig.pluginNamesPaths.hasOwnProperty(k)) {
    loaders.push({
      test: new RegExp('templates\/plugin-' + k.replace(/^openproject\-/, '') + '/.*\.html$'),
      use: [
        {
          loader: 'ngtemplate-loader',
          options: {
            module: 'OpenProjectLegacy',
            relativeTo: path.join(pathConfig.pluginNamesPaths[k], 'frontend', 'app')
          }
        },
        {
          loader: 'html-loader',
          options: {
            minimize: false
          }
        }
      ]
    });
  }
}

loaders.push({
  test: /^((?!templates\/plugin).)*\.html$/,
  use: [
    {
      loader: 'ngtemplate-loader',
      options: {
        module: 'OpenProjectLegacy',
        relativeTo: path.resolve(__dirname, './app')
      }
    },
    {
      loader: 'html-loader',
      options: {
        minimize: false
      }
    }
  ]
});

function getWebpackMainConfig() {
  config = {
    mode: mode,

    devtool: 'source-map',

    context: path.resolve(__dirname, 'app'),

    entry: _.merge({
      'core-app': './openproject-legacy-app'
    }, pluginEntries),

    output: {
      filename: 'openproject-[name].js',
      path: bundle_output,
      publicPath: '/assets/bundles/'
    },

    module: {
      rules: loaders
    },

    resolve: {
      modules: [
        'node_modules',
      ],

      extensions: ['.ts', '.tsx', '.js'],

      // Allow empty import without extension
      // enforceExtension: true,

      alias: _.merge({
        'angular': path.resolve(node_root, 'angular', 'angular.min.js'),
        'angular-dragula': path.resolve(node_root, 'angular-dragula', 'dist', 'angular-dragula.min.js'),
        'core-app': path.resolve(__dirname, 'app'),
        'core-components': path.resolve(__dirname, 'app', 'components'),
      }, pluginAliases)
    },

    externals: {
      "I18n": "I18n",
      "_": "_",
    },

    optimization: {
      splitChunks: {
        cacheGroups: {
          common: {
            name: "common",
            chunks: "initial",
            minChunks: 2
          }
        }
      }
    },

    plugins: [
      // Define modes for debug output
      new webpack.DefinePlugin({
        DEBUG: !!debug_output,
        PRODUCTION: !!production
      }),

      // Clean the output directory
      new CleanWebpackPlugin(['bundles'], {
        root: output_root,
        verbose: true,
        exclude: ['openproject-vendors.js']
      }),

      // new BundleAnalyzerPlugin(),

      new MiniCssExtractPlugin({
        // Options similar to the same options in webpackOptions.output
        // both options are optional
        filename: "openproject-[name].css",
        chunkFilename: "[id].css"
      }),
    ]
  };

  if (production) {
    console.log("Applying webpack.optimize plugins for production.");
    // Add compression and optimization plugins
    // to the webpack build.
    config.plugins.push(
      new webpack.LoaderOptionsPlugin({
        // Let loaders know that we're in minification mode
        minimize: true
      })
    );

    config.optimization.minimizer = [
      // we specify a custom UglifyJsPlugin here to get source maps in production
      new UglifyJsPlugin({
        cache: true,
        parallel: true,
        uglifyOptions: {
          compress: true,
          mangle: false,
          ecma: 5,
        },
        sourceMap: true
      })
    ];
  }

  return config;
}

module.exports = getWebpackMainConfig;
