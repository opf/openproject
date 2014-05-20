angular.module('openproject.workPackages.directives')

.directive('columnContextMenu', [
  'ContextMenuService',
  'I18n',
  'QueryService',
  'WorkPackagesTableHelper',
  'WorkPackagesTableService',
  function(ContextMenuService, I18n, QueryService, WorkPackagesTableHelper, WorkPackagesTableService) {


  return {
    restrict: 'EA',
    replace: true,
    scope: {},
    templateUrl: '/templates/work_packages/column_context_menu.html',
    link: function(scope, element, attrs) {
      var contextMenuName = 'columnContextMenu';

      // Wire up context menu handlers

      ContextMenuService.registerMenuElement(contextMenuName, element);
      scope.contextMenu = ContextMenuService.getContextMenu();

      scope.$watch('contextMenu.opened', function(opened) {
        scope.opened = opened && scope.contextMenu.targetMenu === contextMenuName;
      });
      scope.$watch('contextMenu.targetMenu', function(target) {
        scope.opened = scope.contextMenu.opened && target === contextMenuName;
      });

      // shared context information

      scope.$watch('contextMenu.context.column', function(column) {
        scope.column = column;
      });
      scope.$watch('contextMenu.context.columns', function(columns) {
        scope.columns = columns;
      });

      scope.I18n = I18n;

      // context menu actions

      scope.groupBy = function(columnName) {
        QueryService.getQuery().groupBy = columnName;
      };

      scope.sortAscending = function(columnName) {
        WorkPackagesTableService.sortBy(columnName, 'asc');
      };

      scope.sortDescending = function(columnName) {
        WorkPackagesTableService.sortBy(columnName, 'desc');
      };

      scope.moveLeft = function(columnName) {
        WorkPackagesTableHelper.moveColumnBy(scope.columns, columnName, -1);
      };

      scope.moveRight = function(columnName) {
        WorkPackagesTableHelper.moveColumnBy(scope.columns, columnName, 1);
      };

      scope.hideColumn = function(columnName) {
        QueryService.hideColumns(new Array(columnName));
      };
    }
  };
}]);
