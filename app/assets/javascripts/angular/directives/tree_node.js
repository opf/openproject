uiComponentsApp.directive('treeNode', [function() {
  return {
    restrict: 'A',
    scope: true,
    link: function(scope, element, attributes) {
      scope.node.dom_element = element;

      scope.$watch('node.expanded', function(expanded, formerlyExpanded) {
        if(expanded !== formerlyExpanded) scope.timeline.rebuildAll();
      });
    }
  };
}]);
