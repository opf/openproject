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

module.exports = function(I18n) {
  'use strict';

  var workPackageWatchersLookupController = function(scope) {
    scope.locked = false;
    scope.I18n = I18n;
    scope.addWatcher = function() {
      if (!scope.selectedWatcher) {
        return;
      }

      scope.locked = !scope.locked;

      // we pass up the original up the scope chain,
      // _not_ the wrapper object
      scope.$emit('watchers.add', scope.selectedWatcher.originalObject);
    };

    scope.$on('watchers.add.finished', function() {
      scope.locked = !scope.locked;

      // to clear the input of the directive
      scope.$broadcast('angucomplete-alt:clearInput');

      scope.selectedWatcher = null;

      //set the focus back to allow for next watcher
      angular.element('#watchers-lookup_value').focus();
    });
  };

  return {
    replace: true,
    restrict: 'E',
    templateUrl: '/templates/work_packages/watchers/lookup.html',
    link: workPackageWatchersLookupController,
    scope: {
      watchers: '='
    }
  };
};
