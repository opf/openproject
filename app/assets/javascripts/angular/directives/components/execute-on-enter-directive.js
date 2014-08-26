angular.module('openproject.uiComponents')

.constant('ENTER_KEY', 13)
.directive('executeOnEnter', ['ENTER_KEY', function(ENTER_KEY) {
  return {
    restrict: 'A',
    scope: { executeOnEnter: '&', defaultEventHandling: '=' },
    link: function(scope, element) {
      element.on('keydown', function(event) {
        if(event.which === ENTER_KEY) {
          if (!scope.defaultEventHandling) {
            event.preventDefault();
          }
          scope.$apply(function() {
            scope.$eval(scope.executeOnEnter, { 'event': event });
          });
        }
      });
    }
  };
}]);
