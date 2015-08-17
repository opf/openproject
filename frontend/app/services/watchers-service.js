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

  var watching = function(workPackage) {
        var path = workPackage.links.watchers.url();
        return getWatchers(path)();
      },
      available = function(workPackage) {
        var path = workPackage.links.availableWatchers.url();
        return getWatchers(path)();
      },
      all = function(workPackage) {
        var watchers = $q.defer();
        $q.all([watching(workPackage), available(workPackage)]).then(function(allWatchers) {
          var watching = allWatchers[0],
              available = _.difference(allWatchers[1], allWatchers[0]);
          console.log(available);
          watchers.resolve({ watching: watching, available: available });
        }, function(err) {
          watchers.reject(err);
        });
        return watchers.promise;
      },
      add = function(workPackage, watcher) {
        var added = $q.defer(),
            // somehow, the path will not be correctly inferred when using url()
            path = workPackage.links.addWatcher.props.href,
            method = workPackage.links.addWatcher.props.method,
            payload = {
              user: {
                href: watcher._links.self.href // watcher is not a ressource
              }
            };

        $http[method](path, payload).then(function() {
          added.resolve(watcher);
        }, function(err) {
          added.reject(err);
        });

        return added.promise;
      },
      remove = function(workPackage, watcher) {
        var removed = $q.defer(),
            path = workPackage.links.removeWatcher.props.href,
            method = workPackage.links.removeWatcher.props.method;

        path = path.replace(/\{user\_id\}/, watcher.id);

        $http[method](path).then(function() {
          removed.resolve(watcher);
        }, function(err) {
          remove.reject(err);
        })

        return removed.promise;
      };

  /*
   * NOTE: In theorey, this service is independent from WorkPackages,
   * however, the only thing currently handled by it is WorkPackage
   * related watching.
   * This might change in the future, as other Objects are watchable in
   * OP - e.g. wiki pages.
   *
   * The public interface is therefore designed around handling WPs
   */
  return {
    watchingForWorkPackage: watching,
    availableForWorkPackage: available,
    forWorkPackage: all,
    addForWorkPackage: add,
    removeFromWorkPackage: remove
  };
};
