angular.module('openproject.workPackages.directives')

.directive('workPackageTotalSums', ['WorkPackageService', function(WorkPackageService) {

  return {
    restrict: 'A',
    scope: true,
    compile: function(tElement) {
      return {
        pre: function(scope, iElement, iAttrs, controller) {
          function fetchSums() {
            scope.withLoading(WorkPackageService.getWorkPackagesSums, [scope.projectIdentifier, scope.columns])
              .then(function(sumsData){
                scope.sums = sumsData;
              });
          }

          scope.$watch('columns.length', function() {
            // map columns to sums if the column data is a number
            fetchSums();
          });
        }
      };
    }
  };
}]);
