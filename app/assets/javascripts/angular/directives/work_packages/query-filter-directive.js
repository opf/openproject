angular.module('openproject.workPackages.directives')

.directive('queryFilter', ['WorkPackagesTableHelper', 'WorkPackageService', '$timeout', function(WorkPackagesTableHelper, WorkPackageService, $timeout) {

  return {
    restrict: 'A',
    link: function(scope, element, attributes) {
      scope.availableValues = scope.query.getAvailableFilterValues(scope.filter.name);

      scope.showValueOptionsAsSelect = ['list', 'list_optional', 'list_status', 'list_subprojects'].indexOf(scope.query.getFilterType(scope.filter.name)) !== -1;

      scope.$watch('filter.operator', function(operator) {
        if(operator) scope.showValuesInput = scope.filter.requiresValues();
      });

      scope.$watch('filter', function(filter, oldFilter) {
        if (filter !== oldFilter) {
          if (filter.isConfigured()) {
            applyFiltersWithDelay().then(function(response) {
              scope.setupWorkPackagesTable(response);
            });
          }
        }
      }, true);

      // TODO move to some application helper
      function withDelay(delay, callback, params){
        var currentRun;
        $timeout.cancel(currentRun);

        currentRun = $timeout(function() {
          return callback.apply(this, params);
        }, delay);

        return currentRun;
      }

      function applyFiltersWithDelay() {
        return withDelay(500, WorkPackageService.getWorkPackages, [scope.projectIdentifier, scope.query]);
      }

    }
  };
}]);
