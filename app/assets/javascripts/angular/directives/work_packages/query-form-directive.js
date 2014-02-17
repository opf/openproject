angular.module('openproject.workPackages.directives')

.directive('queryForm', ['WorkPackagesTableHelper', 'QueryService', function(WorkPackagesTableHelper, QueryService) {

  return {
    restrict: 'EA',

    compile: function(tElement) {
      return {
        pre: function(scope) {
          scope.showQueryOptions = false;

          // groupings

          scope.$watch('groupByColumn.name', function(name, formerName) {
            if (name !== formerName) {
              // reset groupByColumn
              scope.groupByColumn = WorkPackagesTableHelper.detectColumnByName(scope.columns, name);
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
