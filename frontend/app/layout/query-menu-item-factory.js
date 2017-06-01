//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

/**
 * queryMenuItemFactory
 *
 * Defines a menu item factory for query menu items, which is set up providing type,
 * container and a link function. The link function makes the item sensitive to its
 * selected state and provides an event-based way to destroy the menu item, signalled
 * by the 'openproject.layout.removeMenuItem' event.
 */
module.exports = function(menuItemFactory, $state, $stateParams, $animate, $timeout, QUERY_MENU_ITEM_TYPE) {
  return menuItemFactory({
    type: QUERY_MENU_ITEM_TYPE,
    container: '#main-menu-work-packages-wrapper ~ .menu-children',
    linkFn: function(scope, element, attrs) {
      scope.queryId = scope.objectId || attrs.objectId;
      scope.uiRouteStateName = 'work-packages.list';
      // Remove any query_props value
      scope.uiRouteParams = '{ query_props: null, query_id: ' + scope.queryId + ' }';

      function setActiveState() {
        // Apparently the queryId sometimes is a number, sometimes a string, sometimes
        // undefined and sometimes null. Use == instead of == to make sure these
        // comparisons work.
        // No idea though, why these sometimes are null and sometimes are undefined.
        element.toggleClass('selected', !!($state.includes('work-packages') &&
                                        scope.queryId == $stateParams.query_id));
      }
      scope.$on('openproject.layout.activateMenuItem', setActiveState);

      scope.$watchCollection(function(){
        return {
          query_id: $stateParams['query_id'],
        };
      }, setActiveState);


      function removeItem() {
        $animate.leave(element.parent(), function () {
          scope.$destroy();
        });
      }

      scope.$on('openproject.layout.removeMenuItem', function(event, itemData) {
        if (itemData.itemType === QUERY_MENU_ITEM_TYPE && itemData.objectId == scope.queryId) {
          removeItem();
        }
      });

      scope.$on('openproject.layout.renameMenuItem', function(event, itemData) {
        if (itemData.itemType === QUERY_MENU_ITEM_TYPE && itemData.objectId == scope.queryId) {
          element.find('.menu-item--title').html(itemData.objectName);
        }
      });
    }
  });
};
