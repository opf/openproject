angular.module('openproject.layout')

.constant('QUERY_MENU_ITEM_TYPE', 'QueryMenuItem')

.directive('queryMenuItem', [
  'queryMenuItemFactory',
  function(queryMenuItemFactory) {
  return {
    restrict: 'A',
    scope: true,
    link: queryMenuItemFactory.link
  };
}]);
