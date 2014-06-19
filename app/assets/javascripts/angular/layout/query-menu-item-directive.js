angular.module('openproject.layout')

.directive('queryMenuItem', [
  '$stateParams',
  function($stateParams) {
  return {
    restrict: 'A',
    scope: { queryId: '@' },
    link: function(scope, element, attrs) {
      scope.$on('$stateChangeSuccess', function() {
        element.toggleClass('selected', scope.queryId === $stateParams.query_id);
      });
    }
  };
}]);
