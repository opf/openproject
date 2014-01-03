timelinesApp.directive('treeNode', function() {
  return {
    restrict: 'A',
    scope: true,
    link: function(scope, element, attributes) {
      scope.node.dom_element = element;
    }
  };
});
