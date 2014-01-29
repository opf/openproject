openprojectApp.directive('timelineTableRow', [function() {
  return {
    restrict: 'A',
    scope: true,
    link: function(scope, element, attributes) {
      // set dom element
      scope.row.dom_element = element;

      scope.$watch('row.expanded', function(expanded, formerlyExpanded) {
        if(expanded !== formerlyExpanded) scope.timeline.rebuildAll();
      });
    }

  };
}]);
