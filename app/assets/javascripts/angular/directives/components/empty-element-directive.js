angular.module('openproject.uiComponents')

.directive('emptyElement', [function() {
  return {
    restrict: 'E',
    scope: { execute: '&' },
    templateUrl: "/templates/components/empty_element.html"
  };
}]);
