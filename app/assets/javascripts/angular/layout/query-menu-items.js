angular.module('openproject.layout')

.constant('QUERY_MENU_ITEM_TYPE', 'query-menu-item')

.factory('queryMenuItemFactory', [
  'menuItemFactory',
  '$stateParams',
  '$animate',
  '$timeout',
  'QUERY_MENU_ITEM_TYPE',
  function(menuItemFactory, $stateParams, $animate, $timeout, QUERY_MENU_ITEM_TYPE) {
  return menuItemFactory({
    itemType: QUERY_MENU_ITEM_TYPE,
    container: '#main-menu-work-packages-wrapper ~ .menu-children',
    linkFn: function(scope, element, attrs) {
      scope.queryId = scope.objectId || attrs.objectId;

      function setActiveState() {
        element.toggleClass('selected', (scope.queryId || null) === $stateParams.query_id);
      }
      $timeout(setActiveState);
      scope.$on('$stateChangeSuccess', setActiveState);

      function removeItem() {
        $animate.leave(element.parent(), function () {
          scope.$destroy();
        });
      }

      scope.$on('openproject.layout.removeMenuItem', function(event, itemData) {
        if (itemData.itemType === QUERY_MENU_ITEM_TYPE && itemData.objectId === scope.queryId) {
          removeItem();
        }
      });
    }
  });
}])

.directive('queryMenuItem', [
  'queryMenuItemFactory',
  function(queryMenuItemFactory) {
  return {
    restrict: 'A',
    scope: true,
    link: queryMenuItemFactory.link
  };
}]);
