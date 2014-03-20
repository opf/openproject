angular.module('openproject.workPackages.directives')

.directive('queryFilter', ['WorkPackagesTableHelper', 'WorkPackageService', 'FunctionDecorators', function(WorkPackagesTableHelper, WorkPackageService, FunctionDecorators) {

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
            scope.query.hasChanged();
            scope.paginationOptions.page = 1; // reset page

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
