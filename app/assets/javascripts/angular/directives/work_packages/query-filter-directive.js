angular.module('openproject.workPackages.directives')

.directive('queryFilter', ['WorkPackagesTableHelper', 'WorkPackageService', 'FunctionDecorators', 'StatusService', function(WorkPackagesTableHelper, WorkPackageService, FunctionDecorators, StatusService) {

  return {
    restrict: 'A',
    link: function(scope, element, attributes) {
      function populateValues(data){
        scope.availableValues = data.statuses.map(function(v){
          return [v.id, v.name.toString()];
        });
      }

      scope.showValueOptionsAsSelect = ['list', 'list_optional', 'list_status', 'list_subprojects', 'list_model'].indexOf(scope.query.getFilterType(scope.filter.name)) !== -1;

      if(scope.query.getFilterType(scope.filter.name) == 'list_model'){
        // Get possible values
        // TODO: Choose users, statuses, priorities etc based on filter something
        StatusService.getStatuses().then(populateValues);
      } else {
        scope.availableValues = scope.query.getAvailableFilterValues(scope.filter.name);
      }

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
