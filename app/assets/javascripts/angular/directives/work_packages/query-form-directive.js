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
            var params =  {
              'c[]': scope.columns
                .map(function(column){
                  return column.name;
                }),
              'group_by': scope.groupBy
            };

            QueryService.getWorkPackages(scope.projectIdentifier, params)
              .then(scope.setupWorkPackagesTable);
          };
        }
      };
    }
  };
}]);
