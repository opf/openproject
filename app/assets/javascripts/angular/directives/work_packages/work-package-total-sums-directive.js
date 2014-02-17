angular.module('openproject.workPackages.directives')

.directive('workPackageTotalSums', ['WorkPackagesHelper', function(WorkPackagesHelper) {

  return {
    restrict: 'A',
    scope: true,
    compile: function(tElement) {
      return {
        pre: function(scope, iElement, iAttrs, controller) {
          function calculateSums() {
            scope.sums = scope.columns.map(function(column){
              return WorkPackagesHelper.getSums(scope.rows, column);
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
