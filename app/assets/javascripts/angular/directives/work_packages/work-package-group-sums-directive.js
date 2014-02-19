angular.module('openproject.workPackages.directives')

.directive('workPackageGroupSums', ['WorkPackagesHelper', 'WorkPackageService', function(WorkPackagesHelper, WorkPackageService) {

  return {
    restrict: 'A',
    scope: true,
    compile: function(tElement) {
      return {
        pre: function(scope, iElement, iAttrs, controller) {
          scope.currentGroup = scope.row.groupName;

          var rowsInCurrentGroup = scope.rows.filter(function(row){
            return row.groupName === scope.currentGroup;
          });

          function calculateSums() {
            scope.sums = scope.columns.map(function(column){
              return WorkPackagesHelper.getSums(rowsInCurrentGroup, column);
            });
          }

          scope.$watch('columns.length', function() {
            // map columns to sums if the column data is a number
            calculateSums();
          });

        }
      };
    }
  };
}]);
