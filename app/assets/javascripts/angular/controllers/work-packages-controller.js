angular.module('openproject.workPackages.controllers')

.controller('WorkPackagesController', ['$scope', 'WorkPackagesTableHelper', function($scope, WorkPackagesTableHelper) {
  $scope.projectIdentifier = gon.project_identifier;

  // Query configuration

  $scope.query = gon.query;
  $scope.showQueryOptions = false;

  // Columns

  // TODO move this stuff to query display options directive
  $scope.columns = gon.columns;
  $scope.availableColumns = WorkPackagesTableHelper.getColumnDifference(gon.available_columns, $scope.columns);
  $scope.selectedAvailableColumns = [];

  // Groups

  $scope.groupBy = $scope.query.group_by;

  groupByColumnIndex = $scope.columns.map(function(column){
    return column.name;
  }).indexOf($scope.groupBy);

  $scope.groupByColumn = $scope.columns[groupByColumnIndex];


  // Work packages table

  $scope.currentSortation = gon.sort_criteria;
  $scope.workPackageCountByGroup = gon.work_package_count_by_group;

  $scope.rows = WorkPackagesTableHelper.getRows(gon.work_packages, $scope.groupBy);

}]);
