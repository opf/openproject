angular.module('openproject.workPackages')

.factory('ColumnContextMenu', [
  'ngContextMenu',
  function(ngContextMenu) {

  return ngContextMenu({
    controller: 'ColumnContextMenuController',
    controllerAs: 'contextMenu',
    templateUrl: '/templates/work_packages/column_context_menu.html'
  });
}])

.controller('ColumnContextMenuController', [
  '$scope',
  'ColumnContextMenu',
  'I18n',
  'QueryService',
  'WorkPackagesTableHelper',
  'WorkPackagesTableService',
  function($scope, ColumnContextMenu, I18n, QueryService, WorkPackagesTableHelper, WorkPackagesTableService) {

    $scope.I18n = I18n;
    $scope.isGroupable = WorkPackagesTableService.isGroupable($scope.column);

    // context menu actions

    $scope.groupBy = function(columnName) {
      QueryService.getQuery().groupBy = columnName;
    };

    $scope.sortAscending = function(columnName) {
      WorkPackagesTableService.sortBy(columnName, 'asc');
    };

    $scope.sortDescending = function(columnName) {
      WorkPackagesTableService.sortBy(columnName, 'desc');
    };

    $scope.moveLeft = function(columnName) {
      WorkPackagesTableHelper.moveColumnBy($scope.columns, columnName, -1);
    };

    $scope.moveRight = function(columnName) {
      WorkPackagesTableHelper.moveColumnBy($scope.columns, columnName, 1);
    };

    $scope.hideColumn = function(columnName) {
      ColumnContextMenu.close();
      QueryService.hideColumns(new Array(columnName));
    };
}]);
