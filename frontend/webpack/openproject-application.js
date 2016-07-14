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
var config = require('./base-config.js')();

function getApplicationConfig() {
  var appRoot = path.resolve(__dirname, '..', 'app');

  config.name = 'OpenProject Application';
  config.context = appRoot;
  config.entry = {
    'global': './global.js',
    'core-app': './openproject-app.js',
  };

  config.output = {
    filename: 'openproject-[name].js',
    path: path.join(__dirname, '..' , '..', 'app', 'assets', 'javascripts', 'bundles'),
    publicPath: '/assets/bundles/'
  };

  return config;
}

module.exports = getApplicationConfig;
