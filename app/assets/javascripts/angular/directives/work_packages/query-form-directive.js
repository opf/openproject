angular.module('openproject.workPackages.directives')

.directive('queryForm', ['WorkPackagesTableHelper', 'QueryService', function(WorkPackagesTableHelper, QueryService) {

  return {
    restrict: 'EA',

    compile: function(tElement) {
      return {
        pre: function(scope) {
          scope.showQueryOptions = false;

          scope.$watch('groupBy', function(oldValue, newValue) {
            if (newValue !== oldValue) {
              scope.reloadWorkPackagesTableData();
            }
          });


          scope.reloadWorkPackagesTableData = function() {
            QueryService.getWorkPackages(scope.projectIdentifier, scope.query)
              .then(scope.setupWorkPackagesTable);
          };
        }
      };
    }
  };
}]);
