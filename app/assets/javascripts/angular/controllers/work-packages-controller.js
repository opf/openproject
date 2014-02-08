openprojectApp.controller('WorkPackagesController', ['$scope', 'WorkPackagesTableHelper', function($scope, WorkPackagesTableHelper) {
  $scope.projectIdentifier = gon.project_identifier;
  $scope.query = gon.query;
  $scope.currentSortation = gon.sort_criteria;

  $scope.workPackagesTable = {
    columns: gon.columns,
    rows: WorkPackagesTableHelper.getRows(gon.work_packages)
  };
}]);
