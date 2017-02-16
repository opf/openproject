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

import {filtersModule} from '../../../angular-modules';

function queryFilterDirective($timeout:ng.ITimeoutService,
                              $animate:any,
                              WorkPackageLoadingHelper:any,
                              QueryService:any,
                              PaginationService:any,
                              I18n:op.I18n,
                              TimezoneService:any,
                              OPERATORS_NOT_REQUIRING_VALUES:any) {
  var updateResultsJob:any;

  return {
    restrict: 'A',
    scope: true,
    link: function (scope:any, element:ng.IAugmentedJQuery) {
      scope.I18n = I18n;
      scope.isLoading = false; // shadow isLoading as its used for a different purpose in this context

      scope.filterModelOptions = {
        updateOn: 'default blur',
        debounce: {'default': 400, 'blur': 0}
      };

      scope.filterDateModelOptions = {
        updateOn: 'default change blur',
        debounce: {'default': 400, 'change': 0, 'blur': 0}
      };

      $animate.enabled(false, element);
      scope.showValueOptionsAsSelect = scope.filter.isSelectInputField();

      if (scope.showValueOptionsAsSelect) {
        WorkPackageLoadingHelper.withLoading(scope, QueryService.getAvailableFilterValues,
          [scope.filter.name, scope.projectIdentifier])

          .then(buildOptions)
          .then(addStandardOptions)
          .then(function (options:any) {
            scope.availableFilterValueOptions = options;
          });
      }

      preselectOperator();

      scope.$on('openproject.workPackages.updateResults', function () {
        $timeout.cancel(updateResultsJob);
      });

      // Filter updates

      scope.$watch('filter.operator', function (operator:any) {
        if (operator && scope.filter.requiresValues) {
          scope.showValuesInput = scope.filter.requiresValues();
        }
      });

      scope.$watch('filter', function (filter:any, oldFilter:any) {
        if (filter !== oldFilter && (filter.hasValues() || filter.isConfigured())
          && (filterChanged(filter, oldFilter) || valueReset(filter, oldFilter))) {

          PaginationService.resetPage();
          scope.$emit('queryStateChange');
          scope.$emit('workPackagesRefreshRequired');
          scope.query.dirty = true;
        }
      }, true);

      function buildOptions(values:any) {
        return values.map(function (value:any) {
          return [value.name, value.id.toString()];
        });
      }

      function addStandardOptions(options:any) {
        if (scope.filter.modelName === 'user') {
          options.unshift([I18n.t('js.label_me'), 'me']);
        }

        return options;
      }

      function filterChanged(filter:any, oldFilter:any) {
        return filter.operator !== oldFilter.operator || !angular.equals(filter.getValuesAsArray(), oldFilter.getValuesAsArray()) ||
          filter.deactivated !== oldFilter.deactivated;
      }

      function valueReset(filter:any, oldFilter:any) {
        return oldFilter.hasValues() && !filter.hasValues();
      }

      function preselectOperator() {
        if (!scope.filter.operator) {
          var operator:any = _.find(
            scope.operatorsAndLabelsByFilterType[scope.filter.type],
            function (operator:any) {
              return OPERATORS_NOT_REQUIRING_VALUES.indexOf(operator['symbol']) === -1;
            }
          );
          scope.filter.operator = operator ? operator['symbol'] : undefined;
        }
      }
    }
  };
}

filtersModule.directive('queryFilter', queryFilterDirective);
