//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

angular.module('openproject.workPackages.directives')

.directive('queryFilters', ['WorkPackagesTableHelper', 'FiltersHelper', 'WorkPackageService', 'I18n', function(WorkPackagesTableHelper, FiltersHelper, WorkPackageService, I18n) {

  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/templates/work_packages/query_filters.html',
    compile: function(tElement) {
      return {
        pre: function(scope) {
          scope.I18n = I18n;
          scope.localisedFilterName = FiltersHelper.localisedFilterName;
          scope.$watch('filterToBeAdded', function(filterName) {
            if (filterName) {
              scope.query.addFilter(filterName);
              scope.filterToBeAdded = undefined;
            }
          });

        }
      };
    }
  };
}]);
