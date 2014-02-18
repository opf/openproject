angular.module('openproject.workPackages.controllers')

.controller('WorkPackagesController', ['$scope', 'WorkPackagesTableHelper', function($scope, WorkPackagesTableHelper) {

  $scope.$watch('groupBy', function() {
    var groupByColumnIndex = $scope.columns.map(function(column){
      return column.name;
    }).indexOf($scope.groupBy);

    $scope.groupByColumn = $scope.columns[groupByColumnIndex];
    $scope.query.group_by = $scope.groupBy; // keep the query in sync
  });

  $scope.setupQuery = function(json) {
    $scope.projectIdentifier = json.project_identifier;

    $scope.query = json.query;

    // Columns
    $scope.columns = json.columns;
    $scope.availableColumns = WorkPackagesTableHelper.getColumnDifference(json.available_columns, $scope.columns);

    $scope.groupBy = $scope.query.group_by;
    $scope.currentSortation = json.sort_criteria;

    angular.extend($scope.query, {
      selectedColumns: $scope.columns
    });
  };


  $scope.setupWorkPackagesTable = function(json) {
    $scope.workPackageCountByGroup = json.work_package_count_by_group;
    $scope.rows = WorkPackagesTableHelper.getRows(json.work_packages, $scope.groupBy);
  };

  // Initially setup scope via gon
  $scope.setupQuery(gon);
  $scope.setupWorkPackagesTable(gon);
}]);
