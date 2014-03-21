angular.module('openproject.workPackages.directives')

.directive('queryFilter', ['WorkPackagesTableHelper', 'WorkPackageService', 'FunctionDecorators', 'QueryService', 'PaginationService', function(WorkPackagesTableHelper, WorkPackageService, FunctionDecorators, QueryService, PaginationService) {

  return {
    restrict: 'A',
    link: function(scope, element, attributes) {

      scope.showValueOptionsAsSelect = ['list', 'list_optional', 'list_status', 'list_subprojects', 'list_model'].indexOf(scope.query.getFilterType(scope.filter.name)) !== -1;

      if (scope.showValueOptionsAsSelect) {
        QueryService.getAvailableFilterValues(scope.filter.name)
          .then(function(values) {
            scope.availableFilterValues = values.map(function(value) {
              return [value.name, value.id];
            });
          });
      }

      // Filter updates

      scope.$watch('filter.operator', function(operator) {
        if(operator) scope.showValuesInput = scope.filter.requiresValues();
      });

      scope.$watch('filter', function(filter, oldFilter) {
        if (filter !== oldFilter) {
          if (filter.isConfigured()) {
            scope.query.hasChanged();
            PaginationService.resetPage();

            applyFiltersWithDelay();
          }
        }
      }, true);

      function applyFiltersWithDelay() {
        return FunctionDecorators.withDelay(800, scope.updateResults);
      }
    }
  };
}]);
