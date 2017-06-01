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

import {filtersModule} from '../../../angular-modules';
import {QueryFilterInstanceSchemaResource} from '../../api/api-v3/hal-resources/query-filter-instance-schema-resource.service'
import {QueryFilterInstanceResource} from '../../api/api-v3/hal-resources/query-filter-instance-resource.service'
import {QueryFilterResource} from '../../api/api-v3/hal-resources/query-filter-resource.service'
import {QueryResource} from '../../api/api-v3/hal-resources/query-resource.service'
import {FormResource} from '../../api/api-v3/hal-resources/form-resource.service'
import {WorkPackageTableFiltersService} from '../../wp-fast-table/state/wp-table-filters.service';

function queryFiltersDirective($timeout:ng.ITimeoutService,
                               I18n:op.I18n,
                               wpTableFilters:WorkPackageTableFiltersService,
                               ADD_FILTER_SELECT_INDEX:any) {

  return {
    restrict: 'E',
    replace: true,
    scope: {},
    templateUrl: '/components/filters/query-filters/query-filters.directive.html',

    compile: function () {
      return {
        pre: function (scope:any) {
          scope.I18n = I18n;
          scope.focusElementIndex;
          scope.remainingFilters = [];

          scope.filters;

          wpTableFilters.observeOnScope(scope).subscribe(initialize);

          scope.$watch('filterToBeAdded', function (filter:any) {
            if (filter) {
              scope.filterToBeAdded = undefined;
              let newFilter = scope.filters.add(filter);
              var index = currentFilterLength();
              updateFilterFocus(index);
              updateRemainingFilters();

              wpTableFilters.replaceIfComplete(scope.filters);
            }
          });

          scope.deactivateFilter = function (removedFilter:QueryFilterInstanceResource) {
            let index = scope.filters.current.indexOf(removedFilter);

            if (removedFilter.isCompletelyDefined()) {
              wpTableFilters.remove(removedFilter);
            } else {
              scope.filters.remove(removedFilter);
            }

            updateFilterFocus(index);

            updateRemainingFilters();
          };

          function initialize() {
            scope.filters = wpTableFilters.currentState;

            updateRemainingFilters();
          }

          function updateRemainingFilters() {
            scope.remainingFilters = scope.filters.remainingFilters;
          }

          function updateFilterFocus(index:number) {
            var activeFilterCount = currentFilterLength();

            if (activeFilterCount == 0) {
              scope.focusElementIndex = ADD_FILTER_SELECT_INDEX;
            } else {
              var filterIndex = (index < activeFilterCount) ? index : activeFilterCount - 1;
              var filter = currentFilterAt(filterIndex);
              scope.focusElementIndex = scope.filters.current.indexOf(filter);
            }

            $timeout(function () {
              scope.$broadcast('updateFocus');
            }, 300);
          }

          function currentFilterLength() {
            return scope.filters.current.length;
          }

          function currentFilterAt(index:number) {
            return scope.filters.current[index];
          }
        }
      };
    }
  };
}

filtersModule.directive('queryFilters', queryFiltersDirective);
