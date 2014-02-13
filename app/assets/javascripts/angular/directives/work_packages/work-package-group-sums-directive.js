angular.module('openproject.workPackages.directives')

.directive('workPackageGroupSums', ['WorkPackagesHelper', function(WorkPackagesHelper) {

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

          // map columns to sums if the column data is a number
          scope.sums = scope.columns.map(function(column){
            return WorkPackagesHelper.getSums(rowsInCurrentGroup, column);
          });

        }
      };
    }
  };
}]);
