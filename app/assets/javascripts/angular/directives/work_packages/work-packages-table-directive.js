angular.module('openproject.workPackages.directives')

.directive('workPackagesTable', ['I18n', 'WorkPackageService', function(I18n, WorkPackageService){
  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/templates/work_packages/work_packages_table.html',
    scope: {
      projectIdentifier: '=',
      columns: '=',
      rows: '=',
      query: '=',
      countByGroup: '=',
      groupBy: '=',
      groupByColumn: '=',
      displaySums: '=',
      totalSums: '=',
      groupSums: '=',
      withLoading: '=',
      setupWorkPackagesTable: '='
    },
    link: function(scope, element, attributes) {
      scope.$watch('query.sortation', function(oldValue, newValue) {
        if (newValue !== oldValue) {
          reloadWorkPackagesTableData();
        }
      });

      function reloadWorkPackagesTableData() {
        scope.withLoading(WorkPackageService.getWorkPackages, [scope.projectIdentifier, scope.query])
          .then(scope.setupWorkPackagesTable);
      };

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
