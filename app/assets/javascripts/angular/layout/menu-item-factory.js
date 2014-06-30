angular.module('openproject.layout')

.factory('menuItemFactory', [
  '$rootScope',
  '$compile',
  '$http',
  '$templateCache',
  '$animate',
  function($rootScope, $compile, $http, $templateCache, $animate) {

  return function(options) {
    if (!options.container) {
      throw new Error('Container must be specified menu item to have exacly one of either `template` or `templateUrl`');
    }

    var templateUrl = '/templates/layout/menu_item.html',
        type        = options.type,
        container   = angular.element(options.container),
        linkFn      = options.linkFn,
        scope;

    function generateMenuItem(title, path, objectId) {
      var menuItem;

      scope = $rootScope.$new(true);

      scope.type = type;
      scope.title = title;
      scope.path = path;
      scope.objectId = objectId;

      $http.get(templateUrl, {
        cache: $templateCache
      }).then(function (response) {
        menuItem = angular.element(response.data);

        if (linkFn) linkFn(scope, menuItem.children('a'), {});

        $compile(menuItem)(scope);
        $animate.enter(menuItem, container);
      });

    }

    return {
      generateMenuItem: generateMenuItem,
      link: linkFn
    };
  };
}])

.factory('queryMenuItemFactory', [
  'menuItemFactory',
  '$stateParams',
  '$animate',
  '$timeout',
  'QUERY_MENU_ITEM_TYPE',
  function(menuItemFactory, $stateParams, $animate, $timeout, QUERY_MENU_ITEM_TYPE) {
  return menuItemFactory({
    itemType: 'query-menu-item',
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
}]);
