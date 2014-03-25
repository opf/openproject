angular.module('openproject.workPackages.directives')

.directive('queryFilters', ['WorkPackagesTableHelper', 'WorkPackageService', function(WorkPackagesTableHelper, WorkPackageService) {

  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/templates/work_packages/query_filters.html',
    compile: function(tElement) {
      return {
        pre: function(scope) {
          scope.showFilters = scope.query.filters.length > 0;

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
