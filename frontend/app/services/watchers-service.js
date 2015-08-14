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


module.exports = function($http, $q) {
  'use strict';

  var getWatchers = function(path) {
    return function() {
      var watchers = $q.defer();
      $http.get(path).success(function(data) {
        watchers.resolve(data._embedded.elements);
      }).error(function(err) {
        watchers.reject(err);
      });
      return watchers.promise;
    };
  };

  var load = function(workPackage) {
        var path = workPackage.links.watchers.url();
        return getWatchers(path)();
      },
      available = function(workPackage) {
        var path = workPackage.links.availableWatchers.url();
        return getWatchers(path)();
      },
      all = function(workPackage) {
        var watchers = $q.defer();
        $q.all([load(workPackage), available(workPackage)]).then(function(allWatchers) {
          var watching = allWatchers[0],
              available = _.difference(allWatchers[1], allWatchers[0]);
          console.log(allWatchers, watching, available);
          watchers.resolve({ watching: watching, available: available });
        }, function(err) {
          watchers.reject(err);
        });
        return watchers.promise;
      };

  return {
    loadForWorkPackage: load,
    availableForWorkPackage: available,
    forWorkPackage: all
  };
};
