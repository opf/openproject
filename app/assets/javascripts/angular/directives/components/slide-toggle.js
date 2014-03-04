angular.module('openproject.uiComponents')

.directive('slideToggle', [function() {
  return {
    restrict: 'A',
    scope: {
      speed: '@',
      collapsed: '='
    },
    link: function(scope, element) {
      if (scope.collapsed) element.hide();

      var defaultSpeed = 'fast';

      scope.$watch('collapsed', function(state, formerState) {
        if (state !== formerState) element.slideToggle(scope.speed || defaultSpeed, null);
      });
    }
  };
}]);
