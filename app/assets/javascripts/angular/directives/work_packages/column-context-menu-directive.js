angular.module('openproject.workPackages.directives')

.directive('columnContextMenu', [
  'ContextMenuService',
  function(ContextMenuService) {
  return {
    restrict: 'EA',
    replace: true,
    scope: {},
    templateUrl: '/templates/work_packages/column_context_menu.html',
    link: function(scope, element, attrs) {
      var contextMenuName = 'columnContextMenu';

      ContextMenuService.registerMenuElement(contextMenuName, element);
      scope.contextMenu = ContextMenuService.getContextMenu();

      scope.$watch('contextMenu.opened', function(opened) {
        scope.opened = opened && scope.contextMenu.targetMenu === contextMenuName;
      });
      scope.$watch('contextMenu.targetMenu', function(target) {
        scope.opened = scope.contextMenu.opened && target === contextMenuName;
      });

    }
  };
}]);
