angular.module('openproject.workPackages.controllers')

.controller('WorkPackagesController', ['$scope', 'WorkPackagesTableHelper', function($scope, WorkPackagesTableHelper) {
  $scope.projectIdentifier = gon.project_identifier;
  $scope.query = gon.query;
  $scope.currentSortation = gon.sort_criteria;
  $scope.workPackageCountByGroup = gon.work_package_count_by_group;

  $scope.workPackagesTable = {
    columns: gon.columns,
    rows: WorkPackagesTableHelper.getRows(gon.work_packages)
  };
}]);
