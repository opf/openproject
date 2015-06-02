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

#!/usr/bin/env node

/**
 * this script is just a temporary solution to deal with the issue of npm outputting the npm
 * shrinkwrap file in an unstable manner.
 *
 * See: https://github.com/npm/npm/issues/3581
 */

var _ = require('lodash');
var sorted = require('sorted-object');
var fs = require('fs');


function cleanModule(module, name) {

  // keep `from` and `resolve` properties for git dependencies, delete otherwise
  if (!(module.resolved && module.resolved.match(/^git:\/\//))) {
    delete module.from;
    delete module.resolved;
  }

  if (name === 'chokidar') {
    if (module.version === '0.8.1') {
      delete module.dependencies;
    }
  }

  _.forEach(module.dependencies, function(mod, name) {
    cleanModule(mod, name);
  });
}


console.log('Reading npm-shrinkwrap.json');
var shrinkwrap = require('./../npm-shrinkwrap.json');

console.log('Cleaning shrinkwrap object');
cleanModule(shrinkwrap, shrinkwrap.name);

console.log('Writing cleaned npm-shrinkwrap.json');
fs.writeFileSync('./npm-shrinkwrap.json', JSON.stringify(sorted(shrinkwrap), null, 2) + "\n");
