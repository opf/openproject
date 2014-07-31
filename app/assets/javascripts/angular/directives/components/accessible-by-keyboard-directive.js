angular.module('openproject.uiComponents')

.directive('accessibleByKeyboard', [function() {
  return {
    restrict: 'E',
    transclude: true,
    scope: { execute: '&' },
    template: "<a execute-on-enter='execute()' ng-click='execute()' href=''>" +
                "<span ng-transclude></span>" +
              "</a>"
  };
}]);
