openprojectApp.controller('WorkPackagesController', ['$scope', 'WorkPackagesTableHelper', function($scope, WorkPackagesTableHelper) {
  $scope.projectIdentifier = gon.project_identifier;
  $scope.workPackagesTable = {
    columns: gon.columns,
    rows: WorkPackagesTableHelper.getRows(gon.work_packages)
  };
  $scope.currentSortation = gon.sort_criteria
}]);
