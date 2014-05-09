angular.module('openproject.workPackages.directives')

.directive('workPackageContextMenu', ['ContextMenuService', 'WorkPackagesTableHelper', 'WorkPackageContextMenuHelper', 'WorkPackageService', 'I18n', function(ContextMenuService, WorkPackagesTableHelper, WorkPackageContextMenuHelper, WorkPackageService, I18n) {
  return {
    restrict: 'EA',
    replace: true,
    scope: {},
    templateUrl: '/templates/work_packages/work_package_context_menu.html',
    link: function(scope, element, attrs) {
      scope.I18n = I18n;
      scope.opened = false;

      // wire up context menu event handler

      ContextMenuService.setTarget(element);
      scope.contextMenu = ContextMenuService.getContextMenu();

      scope.$watch('contextMenu.opened', function(opened) {
        scope.opened = opened;
      });

      scope.$watch('contextMenu.context.row', function() {
        updateContextMenu(getWorkPackagesFromContext(scope.contextMenu.context));
      });

      scope.deleteWorkPackages = function() {
        WorkPackageService.performBulkDelete(getWorkPackagesFromContext(scope.contextMenu.context))
          .success(function(data, status) {
            // TODO wire up to API and processs API response
            scope.$emit('flashMessage', {
              text: I18n.t('js.work_packages.message_successful_bulk_delete')
            });
          })
          .error(function(data, status) {
            // TODO wire up to API and processs API response
            scope.$emit('flashMessage', {
              isError: true,
              text: I18n.t('js.work_packages.message_error_during_bulk_delete')
            });
          });
      };

      function updateContextMenu(workPackages) {
        scope.permittedActions = WorkPackageContextMenuHelper.getPermittedActions(workPackages);
      }

      function getWorkPackagesFromSelectedRows(rows) {
        var selectedRows = WorkPackagesTableHelper.getSelectedRows(rows);

        return WorkPackagesTableHelper.getWorkPackagesFromRows(selectedRows);
      }

      function getWorkPackagesFromContext(context) {
        if (!context.row) return [];

        context.row.checked = true;

        var workPackagefromContext = context.row.object;
        var workPackagesfromSelectedRows = getWorkPackagesFromSelectedRows(context.rows);

        if (workPackagesfromSelectedRows.length === 0) {
          return [workPackagefromContext];
        } else if (workPackagesfromSelectedRows.indexOf(workPackagefromContext) === -1) {
          return [workPackagefromContext].concat(workPackagesfromSelectedRows);
        } else {
          return workPackagesfromSelectedRows;
        }
      }

    }
  };
}]);
