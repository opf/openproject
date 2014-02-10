angular.module('openproject.timelines.directives')

.directive('timelineGroupingLabel', [function() {
  return {
    restrict: 'A',
    scope: true,
    link: function(scope, element, attributes) {
      scope.showGroupingLabel = function() {
        return !scope.$first && scope.row.firstLevelGroup !== scope.rows[scope.$index-1].firstLevelGroup;
      };
    }
  };
  // TODO restrict to 'E' once https://github.com/angular/angular.js/issues/1459 is solved
}]);
