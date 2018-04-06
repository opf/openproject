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
var autoprefixer = require('autoprefixer');

const CKEditorWebpackPlugin = require( '@ckeditor/ckeditor5-dev-webpack-plugin' );
var CleanWebpackPlugin = require('clean-webpack-plugin');
var ExtractTextPlugin = require('extract-text-webpack-plugin');

var mode = (process.env['RAILS_ENV'] || 'production').toLowerCase();
var uglify = (mode !== 'development');

var node_root = path.resolve(__dirname, 'node_modules');
var output_root = path.resolve(__dirname, '..', 'app', 'assets', 'javascripts');
var bundle_output = path.resolve(output_root, 'editor')

function getWebpackCKEConfig() {
  config = {
    entry: {
      ckeditor: [path.resolve(__dirname, 'ckeditor', 'ckeditor.ts')]
    },

    module: {
      rules: [
          {
            test: /\.tsx?$/,
            include: [
              path.resolve(__dirname, 'ckeditor'),
              path.resolve(__dirname, 'app'),
            ],
            use: [
              {
                loader: 'ts-loader',
                options: {
                  logLevel: 'info',
                  configFile: path.resolve(__dirname, 'ckeditor', 'tsconfig.json')
                }
              }
            ]
          },
          {
              // Or /ckeditor5-[^/]+\/theme\/icons\/[^/]+\.svg$/ if you want to limit this loader
              // to CKEditor 5's icons only.
              test: /\.svg$/,

              use: [ 'raw-loader' ]
          },
          {
              // Or /ckeditor5-[^/]+\/theme\/[^/]+\.scss$/ if you want to limit this loader
              // to CKEditor 5's theme only.
              test: /\.css$/,

              use: [
                'style-loader',
                {
                  loader: 'postcss-loader',
                  options: {
                    config: { path: path.resolve(__dirname, 'ckeditor', 'postcss.config.js') }
                  }
                }
              ]
          },
          {
            // Or /ckeditor5-[^/]+\/theme\/[^/]+\.scss$/ if you want to limit this loader
            // to CKEditor 5's theme only.
            test: /\.scss$/,

            use: [
              'style-loader',
              {
                loader: 'css-loader',
                options: {
                  minimize: true
                }
              },
              'sass-loader'
            ]
          }
      ]
    },

    output: {
      path: bundle_output,
      filename: 'openproject-[name].js',
      library: '[name]'
    },

    resolve: {
      modules: ['node_modules'],
      extensions: ['.ts', '.tsx', '.js'],
      alias: _.merge({
        'core-components': path.resolve(__dirname, 'app', 'components'),
        'op-ckeditor': path.resolve(__dirname, 'ckeditor'),
      })
    },

    plugins: [


      // Editor i18n TODO
      new CKEditorWebpackPlugin({
        // See https://ckeditor5.github.io/docs/nightly/ckeditor5/latest/features/ui-language.html
        languages: [ 'en' ]
      }),


      // Clean the output directory
      new CleanWebpackPlugin(['editor'], {
        root: output_root,
        verbose: true
      })
    ]
  };

  return config;
}

module.exports = getWebpackCKEConfig;
