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

var webpack  = require('webpack'),
  fs         = require('fs'),
  path       = require('path'),
  _          = require('lodash'),
  pathConfig = require('./rails-plugins.conf');

var ExtractTextPlugin = require('extract-text-webpack-plugin');

var pluginEntries = _.reduce(pathConfig.pluginNamesPaths, function(entries, path, name) {
  entries[name.replace(/^openproject\-/, '')] = name;
  return entries;
}, {});

var pluginAliases = _.reduce(pathConfig.pluginNamesPaths, function(entries, pluginPath, name) {
  entries[name] = path.basename(pluginPath);
  return entries;
}, {});

var browsersListConfig = fs.readFileSync(path.join(__dirname, '..', 'browserslist'), 'utf8');
var browsersList = JSON.stringify(_.filter(browsersListConfig.split('\n'), function(entry) {
  return entry && entry.charAt(0) !== '#';
}));

var loaders = [
  { test: /\.ts$/,                    loader: 'ng-annotate!ts-loader' },
  { test: /[\/]angular\.js$/,         loader: 'exports?angular' },
  { test: /[\/]jquery\.js$/,          loader: 'expose?jQuery' },
  { test: /[\/]dragula\.js$/,         loader: 'expose?dragula' },
  { test: /[\/]moment\.js$/,          loader: 'expose?moment' },
  { test: /[\/]mousetrap\.js$/,       loader: 'expose?Mousetrap' },
  { test: /[\/]vendor[\/]i18n\.js$/,  loader: 'expose?I18n' },
  {
    test: /\.css$/,
    loader: ExtractTextPlugin.extract(
      'style-loader',
      'css-loader!autoprefixer-loader?{browsers:' + browsersList + ',cascade:false}'
    )
  },
  { test: /\.png$/,                   loader: 'url-loader?limit=100000&mimetype=image/png' },
  { test: /\.gif$/,                   loader: 'file-loader' },
  { test: /\.jpg$/,                   loader: 'file-loader' },
  { test: /js-[\w|-]{2,5}\.yml$/,     loader: 'json!yaml' },
  { test: /[\/].*\.js$/,              loader: 'ng-annotate?map=true' }
];

for (var k in pathConfig.pluginNamesPaths) {
  if (pathConfig.pluginNamesPaths.hasOwnProperty(k)) {
    loaders.push({
      test: new RegExp('templates/plugin-' + k.replace(/^openproject\-/, '') + '/.*\.html$'),
      loader: 'ngtemplate?module=openproject.templates&relativeTo=' +
        path.join(pathConfig.pluginNamesPaths[k], 'frontend', 'app') + '!html'
    });
  }
}

loaders.push({
  test: /^((?!templates\/plugin).)*\.html$/,
  loader: 'ngtemplate?module=openproject.templates&relativeTo=' +
    path.resolve(__dirname, './app') + '!html'
});

module.exports = {
  context: __dirname + '/app',

  entry: _.merge({
    'global':   './global.js',
    'core-app': './openproject-app.js'
  }, pluginEntries),

  output: {
    filename: 'openproject-[name].js',
    path: path.join(__dirname, '..', 'app', 'assets', 'javascripts', 'bundles'),
    publicPath: '/assets/bundles/'
  },

  module: {
    loaders: loaders,
    // Prevent 'This seems to be a pre-built javascript file.' error due to crossvent dist
    noParse: /node_modules\/crossvent/,
  },

  resolve: {
    root: __dirname,

    extensions: ['', '.webpack.js', '.ts', '.js'],

    modulesDirectories: [
      'node_modules',
      'bower_components',
      'vendor'
    ].concat(pathConfig.pluginDirectories),

    fallback: [ path.join(__dirname, 'bower_components') ],

    alias: _.merge({
      'locales':        './../../config/locales',

      'angular-ui-date': 'angular-ui-date/src/date',
      'angular-truncate': 'angular-truncate/src/truncate',
      'angular-context-menu': 'angular-context-menu/dist/angular-context-menu.js',
      'mousetrap': 'mousetrap/mousetrap.js',
      'hyperagent': 'hyperagent/dist/hyperagent',
      'openproject-ui_components':
        'openproject-ui_components/app/assets/javascripts/angular/ui-components-app',
      'ngFileUpload': 'ng-file-upload/ng-file-upload'
    }, pluginAliases)
  },

  resolveLoader: {
    root: __dirname + '/node_modules'
  },

  plugins: [
    new ExtractTextPlugin('openproject-[name].css'),
    new webpack.ProvidePlugin({
      '_':            'lodash',
      'URI':          'URIjs',
      'URITemplate':  'URIjs/src/URITemplate'
    }),
    new webpack.ResolverPlugin([
      new webpack.ResolverPlugin.DirectoryDescriptionFilePlugin(
        'bower.json', ['main'])
    ]) // ['normal', 'loader']
  ]
};
