angular.module('openproject.uiComponents')

.directive('emptyElement', [function() {
  return {
    restrict: 'E',
    templateUrl: "/templates/components/empty_element.html"
  };
}]);
