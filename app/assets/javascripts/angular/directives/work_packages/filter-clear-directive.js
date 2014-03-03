angular.module('openproject.workPackages.directives')

.directive('filterClear', [function(){
  return {
    restrict: 'E',
    templateUrl: '/templates/work_packages/filter_clear.html',
    // scope: {
    //   query: '='
    // },
    scope: true,
    link: function(scope, element, attributes) {
      scope.clearFilter = function(){
        scope.query.clearFilters();
      }
    }
  };
}]);
