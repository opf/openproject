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
              .then(function(data){
                scope.sums = data.column_sums;
              });
          }

          scope.$watch('columns.length', function(length, formerLength) {
            // map columns to sums if the column data is a number
            if(length >= formerLength) fetchSums();
          });
        }
      };
    }
  };
}]);
