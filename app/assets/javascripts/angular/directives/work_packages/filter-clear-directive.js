angular.module('openproject.workPackages.directives')

.directive('filterClear', [function(){
  return {
    restrict: 'E',
    templateUrl: '/templates/work_packages/filter_clear.html',
    scope: true,
    link: function(scope, element, attributes) {
      scope.clearQuery = function(){
        scope.query.clearAll();
      }
    }
  };
}]);
