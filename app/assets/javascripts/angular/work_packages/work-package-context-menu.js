angular.module('openproject.workPackages')

.factory('WorkPackageContextMenu', [
  'ngContextMenu',
  function(ngContextMenu) {

  return ngContextMenu({
    controller: 'WorkPackageContextMenuController',
    controllerAs: 'contextMenu',
    templateUrl: '/templates/work_packages/work_package_context_menu.html'
  });
}])

.controller('WorkPackageContextMenuController', [
  '$scope',
  'WorkPackagesTableHelper',
  'WorkPackageContextMenuHelper',
  'WorkPackageService',
  'WorkPackagesTableService',
  'I18n',
  '$window',
  function($scope, WorkPackagesTableHelper, WorkPackageContextMenuHelper, WorkPackageService, WorkPackagesTableService, I18n, $window) {

  $scope.I18n = I18n;

  $scope.hideResourceActions = true;

  $scope.$watch('row', function() {
    $scope.row.checked = true;
    $scope.permittedActions = WorkPackageContextMenuHelper.getPermittedActions(getSelectedWorkPackages());
  });


  $scope.triggerContextMenuAction = function(action, link) {
    if (action === 'delete') {
      deleteSelectedWorkPackages();
    } else {
      $window.location.href = link;
    }
  };

  function deleteSelectedWorkPackages() {
    if (!deleteConfirmed()) return;

    var rows = WorkPackagesTableHelper.getSelectedRows($scope.rows);

    WorkPackageService.performBulkDelete(getSelectedWorkPackages())
      .success(function(data, status) {
        // TODO wire up to API and processs API response
        $scope.$emit('flashMessage', {
          isError: false,
          text: I18n.t('js.work_packages.message_successful_bulk_delete')
        });

        WorkPackagesTableService.removeRows(rows);
      })
      .error(function(data, status) {
        // TODO wire up to API and processs API response
        $scope.$emit('flashMessage', {
          isError: true,
          text: I18n.t('js.work_packages.message_error_during_bulk_delete')
        });
      });
  }

  function deleteConfirmed() {
    return $window.confirm(I18n.t('js.text_work_packages_destroy_confirmation'));
  }

  function getWorkPackagesFromSelectedRows() {
    var selectedRows = WorkPackagesTableHelper.getSelectedRows($scope.rows);

    return WorkPackagesTableHelper.getWorkPackagesFromRows(selectedRows);
  }

  function getSelectedWorkPackages() {
    var workPackagefromContext = $scope.row.object;
    var workPackagesfromSelectedRows = getWorkPackagesFromSelectedRows();

    if (workPackagesfromSelectedRows.length === 0) {
      return [workPackagefromContext];
    } else if (workPackagesfromSelectedRows.indexOf(workPackagefromContext) === -1) {
      return [workPackagefromContext].concat(workPackagesfromSelectedRows);
    } else {
      return workPackagesfromSelectedRows;
    }
  }

}]);
