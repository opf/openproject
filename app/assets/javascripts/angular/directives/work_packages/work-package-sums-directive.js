angular.module('openproject.workPackages.directives')

.directive('workPackageSums', ['WorkPackagesHelper', function(WorkPackagesHelper) {

  return {
    restrict: 'A',
    scope: true,
    compile: function(tElement) {
      return {
        pre: function(scope, iElement, iAttrs, controller) {
          scope.currentGroup = WorkPackagesHelper.getRowObjectContent(scope.row.object, scope.groupBy); // TODO get group directly from row

          var rowsInCurrentGroup = scope.rows.filter(function(row){
            return WorkPackagesHelper.getRowObjectContent(row.object, scope.groupBy) === scope.currentGroup;
          });

          // map columns to sums if the column data is a number
          scope.sums = scope.columns.map(function(column){
            return getSum(rowsInCurrentGroup, column.name);
          });

          function getSum(rows, columnName) {
            var values = rows
              .map(function(row){
                return WorkPackagesHelper.getRowObjectContent(row.object, columnName);
              })
              .filter(function(value) {
                return typeof(value) === 'number';
              });

            if (values.length > 0) {
              sum = values.reduce(function(a, b) {
                return a + b;
              });
            } else {
              sum = null;
            }

            return sum;
          }
        }
      };
    }
  };
}]);
