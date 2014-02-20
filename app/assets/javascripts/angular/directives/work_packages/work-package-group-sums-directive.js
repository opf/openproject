angular.module('openproject.workPackages.directives')

.directive('workPackageGroupSums', ['WorkPackagesHelper', 'WorkPackageService', function(WorkPackagesHelper, WorkPackageService) {

  return {
    restrict: 'A',
    scope: true,
    compile: function(tElement) {
      return {
        pre: function(scope, iElement, iAttrs, controller) {
          scope.currentGroup = scope.row.groupName;

          function setSums() {
            if(scope.groupSums == null) return;
            scope.sums = scope.groupSums.map(function(groupSum){
              return groupSum[scope.currentGroup];
            });
          }

          scope.$watch('groupSums.length', function() {
            // map columns to sums if the column data is a number
            setSums();
          });

        }
      };
    }
  };
}]);
