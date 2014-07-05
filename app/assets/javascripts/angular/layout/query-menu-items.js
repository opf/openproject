//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

angular.module('openproject.layout')

.constant('QUERY_MENU_ITEM_TYPE', 'query-menu-item')

/**
 * queryMenuItemFactory
 *
 * Defines a menu item factory for query menu items, which is set up providing type,
 * container and a link function. The link function makes the item sensitive to its
 * selected state and provides an event-based way to destroy the menu item, signalled
 * by the 'openproject.layout.removeMenuItem' event.
 */
.factory('queryMenuItemFactory', [
  'menuItemFactory',
  '$stateParams',
  '$animate',
  '$timeout',
  'QUERY_MENU_ITEM_TYPE',
  'QueryService',
  function(menuItemFactory, $stateParams, $animate, $timeout, QUERY_MENU_ITEM_TYPE, QueryService) {
  return menuItemFactory({
    type: QUERY_MENU_ITEM_TYPE,
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

      scope.$on('openproject.layout.renameQueryMenuItem', function(event, itemData) {
        if (itemData.itemType === QUERY_MENU_ITEM_TYPE && itemData.queryId === scope.queryId) {
          QueryService.updateHighlightName()
          .then(function() {
            element.html(itemData.queryName);
          });
        }
      });
    }
  });
}])

/**
 * queryMenuItem directive
 *
 * Patches query menu items generated on the server-side by applying the link function provided
 * by the queryMenuItemFactory.
 * The link function makes the query menu item's 'selected' class reflect the application state
 * and provides an event-based mechanism to remove the item on the fly.
 */
.directive('queryMenuItem', [
  'queryMenuItemFactory',
  function(queryMenuItemFactory) {
  return {
    restrict: 'A',
    scope: true,
    link: queryMenuItemFactory.link
  };
}]);
