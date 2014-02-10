angular.module('openproject.workPackages.directives')

.directive('workPackageGroupHeader', ['WorkPackagesTableHelper', function(WorkPackagesTableHelper) {

  return {
    restrict: 'A',
    compile: function(tElement) {
      return {
        pre: function(scope, iElement, iAttrs, controller) {
          scope.currentGroup = WorkPackagesTableHelper.getRowObjectContent(scope.row.object, scope.groupBy); // TODO get group directly from row

          pushGroup(scope.currentGroup);

          scope.toggleAllGroups = function() {
            var targetExpansion = !scope.groupExpanded[scope.currentGroup];

            angular.forEach(scope.groupExpanded, function(currentExpansion, group) {
              scope.groupExpanded[group] = targetExpansion;
            });
          };

          scope.toggleCurrentGroup = function() {
            scope.groupExpanded[scope.currentGroup] = !scope.groupExpanded[scope.currentGroup];
          };

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
