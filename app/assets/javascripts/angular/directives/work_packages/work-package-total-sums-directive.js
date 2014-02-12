angular.module('openproject.workPackages.directives')

.directive('workPackageTotalSums', ['WorkPackagesHelper', function(WorkPackagesHelper) {

  return {
    restrict: 'A',
    scope: true,
    compile: function(tElement) {
      return {
        pre: function(scope, iElement, iAttrs, controller) {
          scope.sums = scope.columns.map(function(column){
            return WorkPackagesHelper.getSums(scope.rows, column);
          });

        }
      };
    }
  };
}]);
