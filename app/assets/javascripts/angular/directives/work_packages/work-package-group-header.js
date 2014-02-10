angular.module('openproject.workPackages.directives')

.directive('workPackageGroupHeader', ['WorkPackagesTableHelper', function(WorkPackagesTableHelper) {

  return {
    restrict: 'A',
    scope: true,
    compile: function(tElement) {
      return {
        pre: function(scope, iElement, iAttrs, controller) {
          scope.currentGroup = WorkPackagesTableHelper.getRowObjectContent(scope.row.object, scope.groupBy); // TODO get group directly from row

          pushGroup(scope.currentGroup);

          function pushGroup(group) {
            if (scope.groupExpanded[group] === undefined) {
              scope.groupExpanded[group] = true;
            }
          }
        }
      };
    }
  };
}]);
