angular.module('openproject.workPackages.directives')

.directive('workPackageContextMenu', ['ContextMenuService', function(ContextMenuService) {
  return {
    restrict: 'EA',
    replace: true,
    scope: {},
    templateUrl: '/templates/work_packages/work_package_context_menu.html',
    link: function(scope, element, attrs) {
      ContextMenuService.setTarget(element);

      scope.contextMenu = ContextMenuService.getContextMenu();
      scope.opened = false;

      scope.$watch('contextMenu.opened', function(opened) {
        scope.opened = opened;
      });

      scope.$watch('contextMenu.context.row', function() {
        console.log({context: scope.contextMenu.context});
        updateContextMenu(getWorkPackagesFromContext(scope.contextMenu.context));
      });

      function getWorkPackagesFromSelectedRows(rows) {
        return rows
          .filter(function(row) {
            return row.checked;
          })
          .map(function(row) {
            return row.object;
          });
      }

      function getWorkPackagesFromContext(context) {
        if (!context.row) return [];

        var workPackagefromContext = context.row.object;
        var workPackagesfromSelectedRows = getWorkPackagesFromSelectedRows(context.rows);

        if (workPackagesfromSelectedRows.length === 0) {
          return [workPackagefromContext];
        } else if (workPackagesfromSelectedRows.indexOf(workPackagefromContext) === -1) {
          context.row.checked = true;
          return [workPackagefromContext].concat(workPackagesfromSelectedRows);
        } else {
          return workPackagesfromSelectedRows;
        }
      }

      function updateContextMenu(workPackages) {
        console.log({workPackage: workPackages});
      }
    }
  };
}]);
