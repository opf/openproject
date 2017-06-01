//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

/*global exec */
/*global test */

require('shelljs/global');
var path = require('path'),
    _    = require('lodash');

var PLUGIN_INFO_CMD_PATH = path.join(__dirname, '..', 'bin', 'plugin_info');

function runPluginsInfo() {
  var currentWorkingDir = process.cwd();
  // Make sure we're in the root directory to launch the plugin_info script
  process.chdir(path.join(__dirname, '..'));
  var fullCmd = exec(PLUGIN_INFO_CMD_PATH, { silent: false });
  process.chdir(currentWorkingDir);
  return fullCmd.code === 0 ? fullCmd.output : '{}';
}

var OpenProjectPlugins = {
  allPluginNamesPaths: _.memoize(function() {
    return JSON.parse(runPluginsInfo());
  }),

  pluginNamesPaths: function() {
    return _.reduce(this.allPluginNamesPaths(), function(obj, pluginPath, pluginName) {
      if (test('-e', path.join(pluginPath, 'package.json'))) {
        obj[pluginName] = pluginPath;
      }
      return obj;
    }, {});
  },

  findPluginPath: _.memoize(function(name) {
    return this.pluginNamesPaths()[name];
  }, _.identity),

  pluginDirectories: function() {
    return _.reduce(this.allPluginNamesPaths(), function(dirList, pluginPath) {
      var pluginDir = path.dirname(pluginPath);
      return dirList.indexOf(pluginDir) === -1 ? dirList.concat(pluginDir) : dirList;
    }, []);
  }
};

exports.allPluginNamesPaths       = OpenProjectPlugins.allPluginNamesPaths();
exports.pluginNamesPaths          = OpenProjectPlugins.pluginNamesPaths();
exports.pluginDirectories         = OpenProjectPlugins.pluginDirectories();
