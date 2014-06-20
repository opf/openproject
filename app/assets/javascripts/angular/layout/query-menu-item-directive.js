angular.module('openproject.layout')

.constant('QUERY_MENU_ITEM_TYPE', 'QueryMenuItem')

.directive('queryMenuItem', [
  '$stateParams',
  '$animate',
  'QUERY_MENU_ITEM_TYPE',
  function($stateParams, $animate, QUERY_MENU_ITEM_TYPE) {
  return {
    restrict: 'A',
    scope: { queryId: '@' },
    link: function(scope, element, attrs, menuSectionController) {
      scope.$on('$stateChangeSuccess', function() {
        element.toggleClass('selected', (scope.queryId || null) === $stateParams.query_id);
      });

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
  };
}]);
