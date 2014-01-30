openprojectApp.directive('timelineTableRow', [function() {
  return {
    restrict: 'A',
    // TODO restrict to 'E' once https://github.com/angular/angular.js/issues/1459 is solved
    scope: true,
    link: function(scope, element, attributes) {
      scope.rowObject = scope.row.payload;
      scope.indent = scope.hideTreeRoot ? scope.row.level-1 : scope.row.level;

      // set dom element
      scope.row.dom_element = element;

      scope.$watch('row.expanded', function(expanded, formerlyExpanded) {
        if(expanded !== formerlyExpanded) scope.timeline.rebuildAll();
      });
    }
  };
}]);
