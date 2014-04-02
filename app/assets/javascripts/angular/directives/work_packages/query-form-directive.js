angular.module('openproject.workPackages.directives')

.directive('queryForm', ['WorkPackagesTableHelper', 'WorkPackageService', function(WorkPackagesTableHelper, WorkPackageService) {

  return {
    restrict: 'EA',

    compile: function(tElement) {
      return {
        pre: function(scope) {
          scope.showQueryOptions = false;

          scope.$watch('query.group_by', function(oldValue, newValue) {
            if (newValue !== oldValue && newValue !== undefined) {
              // TODO find out why newValue get set to undefined on initial page load
              scope.updateResults();
            }
          });
        }
      };
    }
  };
}]);
