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

require('./controllers');

angular.module('openproject.layout')
  .factory('menuItemFactory', [
    '$rootScope',
    '$compile',
    '$http',
    '$templateCache',
    '$animate',
    require('./menu-item-factory')
  ])

.constant('QUERY_MENU_ITEM_TYPE', 'query-menu-item')
  .factory('queryMenuItemFactory', [
    'menuItemFactory',
    '$state',
    '$stateParams',
    '$animate',
    '$timeout',
    'QUERY_MENU_ITEM_TYPE',
    require('./query-menu-item-factory')
  ])
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
    }
  ]);
