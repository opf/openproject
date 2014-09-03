angular.module('openproject.uiComponents')

.directive('accessibleElement', [function() {
  return {
    restrict: 'E',
    scope: { 
      visibleText: '=',
      readableText: '=',
    },
    templateUrl: "/templates/components/accessible_element.html"
  };
}]);
