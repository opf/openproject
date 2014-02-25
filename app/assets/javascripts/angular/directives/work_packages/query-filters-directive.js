angular.module('openproject.workPackages.directives')

.directive('queryFilters', ['WorkPackagesTableHelper', 'WorkPackageService', function(WorkPackagesTableHelper, WorkPackageService) {

  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/templates/work_packages/query_filters.html',
    compile: function(tElement) {
      return {
        pre: function(scope) {
          scope.showFilters = scope.query.id !== null;

          scope.$watch('filterToBeAdded', function(filterName) {
            if (filterName) {
              scope.query.addFilter(filterName);
              scope.filterToBeAdded = undefined;
            }
          });
          scope.query.filters = [];
          // scope.query.filters = [new Filter({name: 'status_id', operator: 'o', values: undefined}),
          //                        new Filter({name: 'subject', operator: '!~', values: undefined}),
          //                        new Filter({name: 'created_at', operator: 't-', values: undefined})]; // Mock

        }
      };
    }
  };
}]);
