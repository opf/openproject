angular.module('openproject.uiComponents')

.directive('accessibleByKeyboard', [function() {
  return {
    restrict: 'E',
    transclude: true,
    scope: { execute: '&' },
    template: "<a execute-on-enter='execute()' default-event-handling='defaultEventHandling' ng-click='execute()' href=''>" +
                "<span ng-transclude></span>" +
              "</a>",
    link: function(scope, element, attrs) {
      scope.defaultEventHandling = !attrs.execute;
    }
  };
}]);
