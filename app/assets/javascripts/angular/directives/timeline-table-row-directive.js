openprojectApp.directive('timelineTableRow', [function() {
  return {
    restrict: 'A',
    scope: true,
    link: function(scope, element, attributes) {
      scope.rowObject = scope.row.payload;
      scope.indent = scope.isGrouping ? scope.row.level-1 : scope.row.level;

      // set dom element
      scope.row.dom_element = element;

      scope.$watch('row.expanded', function(expanded, formerlyExpanded) {
        if(expanded !== formerlyExpanded) scope.timeline.rebuildAll();
      });
    }

  };
}]);
