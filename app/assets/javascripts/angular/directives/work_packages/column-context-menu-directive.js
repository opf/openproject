angular.module('openproject.workPackages.directives')

.directive('columnContextMenu', [
  'ContextMenuService',
  'I18n',
  'QueryService',
  function(ContextMenuService, I18n, QueryService) {


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
      scope.$watch('contextMenu.context.column', function(column) {
        scope.column = column;
      });

      scope.I18n = I18n;

      scope.groupBy = function(groupBy) {
        QueryService.getQuery().groupBy = groupBy;
      };
    }
  };
}]);
