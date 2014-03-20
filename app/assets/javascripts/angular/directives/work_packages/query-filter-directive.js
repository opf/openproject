angular.module('openproject.workPackages.directives')

.directive('queryFilter', ['WorkPackagesTableHelper', 'WorkPackageService', 'FunctionDecorators', 'StatusService', function(WorkPackagesTableHelper, WorkPackageService, FunctionDecorators, StatusService) {

  return {
    restrict: 'A',
    link: function(scope, element, attributes) {
      function populateValues(data){
        // Do something...
      }

      // TODO RS: We need to extend this so that it gets possible values from the api if it is a 'list_model' filter
      scope.availableValues = scope.query.getAvailableFilterValues(scope.filter.name);

      scope.showValueOptionsAsSelect = ['list', 'list_optional', 'list_status', 'list_subprojects', 'list_model'].indexOf(scope.query.getFilterType(scope.filter.name)) !== -1;

      // if(scope.filter.name == 'list_model'){
      //   // Get possible values
      //   StatusesService.getStatuses().then(populateValues);
      // }

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
