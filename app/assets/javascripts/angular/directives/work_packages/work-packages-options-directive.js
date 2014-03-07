angular.module('openproject.workPackages.directives')

.directive('workPackagesOptions', ['I18n', function(I18n){
  return {
    restrict: 'E',
    templateUrl: '/templates/work_packages/work_packages_options.html',
    link: function(scope, element, attributes) {
      scope.$watch('query.group_by', function() {
        var groupByColumnIndex = scope.columns.map(function(column){
          return column.name;
        }).indexOf(scope.query.group_by);

        scope.groupByColumn = scope.columns[groupByColumnIndex];
      });
    }
  };
}]);
