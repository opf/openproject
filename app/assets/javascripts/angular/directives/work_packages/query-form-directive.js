angular.module('openproject.workPackages.directives')

.directive('queryForm', ['WorkPackagesTableHelper', function(WorkPackagesTableHelper) {

  return {
    restrict: 'EA',
    // replace: true,
    // templateUrl: '/templates/work_packages/query_columns.html',
    compile: function(tElement) {
      return {
        pre: function(scope) {
          // groupings

          if (scope.groupByColumn) scope.groupByColumnName = scope.groupByColumn.name;

          scope.$watch('groupByColumnName', function(name, formerName) {
            if (name !== formerName) {
              // reset groupByColumn
              scope.groupByColumn = WorkPackagesTableHelper.detectColumnByName(scope.columns, name);
            }
          });
        }
      };
    }
  };
}]);
