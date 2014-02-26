angular.module('openproject.workPackages.directives')

.directive('workPackagesTable', ['I18n', function(I18n){
  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/templates/work_packages/work_packages_table.html',
    scope: {
      projectIdentifier: '=',
      columns: '=',
      rows: '=',
      currentSortation: '=',
      countByGroup: '=',
      groupBy: '=',
      groupByColumn: '=',
      displaySums: '=',
      totalSums: '=',
      groupSums: '=',
      withLoading: '='
    },
    link: function(scope, element, attributes) {
      scope.I18n = I18n;

      // groupings

      scope.grouped = scope.groupByColumn !== undefined;
      scope.groupExpanded = {};

      scope.setCheckedStateForAllRows = function(state) {
        angular.forEach(scope.rows, function(row) {
          row.checked = state;
        });
      };

    }
  };
}]);
