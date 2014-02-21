angular.module('openproject.workPackages.directives')

.directive('queryFilter', ['WorkPackagesTableHelper', 'WorkPackageService', function(WorkPackagesTableHelper, WorkPackageService) {

  return {
    restrict: 'A',
    link: function(scope, element, attributes) {
      scope.availableValues = scope.query.getAvailableFilterValues(scope.filter.name);

      scope.showValueOptionsAsSelect = ['list', 'list_optional', 'list_status', 'list_subprojects'].indexOf(scope.query.getFilterType(scope.filter.name)) !== -1;

      scope.$watch('filter.operator', function(operator) {
        if(operator) scope.showValuesInput = scope.filter.requiresValues();
      });


    }
  };
}]);
