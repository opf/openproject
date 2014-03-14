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

          // TODO RS: Moved this into the Query constructor so this isn't dry. Still necessary?
          scope.query.filters = scope.query.filters.map(function(filter){
            var name = Object.keys(filter)[0];
            return new Filter(angular.extend(filter[name], { name: name }));
          });
        }
      };
    }
  };
}]);
