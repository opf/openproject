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
 * menuItemFactory
 *
 * Provides a function to generate menu items for the project menu on the fly.
 * The container element of the menu items to be inserted is a mandatory option. Moreover a
 * link function can be set, which will be applied to the generated menu item.
 *
 * An example for setting up the factory is given in angular/layout/query-menu-items.js
 */
module.exports = function($rootScope, $compile, $http, $templateCache, $animate) {

  return function(options) {
    if (!options.container) {
      throw new Error('Container must be specified menu item to have exacly one of either `template` or `templateUrl`');
    }

    var templateUrl = '/templates/layout/menu_item.html',
        type        = options.type,
        linkFn      = options.linkFn,
        container, scope;

    function getContainer() {
      return angular.element(options.container);
    }

    function generateMenuItem(title, path, objectId) {
      container = getContainer();
      if(!container) return;

      var menuItem;

      scope = $rootScope.$new(true);

      scope.type = type;
      scope.title = title;
      scope.path = path;
      scope.objectId = objectId;

      return $http.get(templateUrl, {
        cache: $templateCache
      }).then(function (response) {
        menuItem = angular.element(response.data);

        if (linkFn) linkFn(scope, menuItem.children('a'), {});

        $compile(menuItem)(scope);

        var previousItem = previousMenuItem(title);
        return $animate.enter(menuItem, container, previousItem);
      });
    }

    function removeMenuItem(id) {
      $rootScope.$broadcast('openproject.layout.removeMenuItem', {
        itemType: type,
        objectId: id
      });
    }

    function renameMenuItem(id, name) {
      $rootScope.$broadcast('openproject.layout.renameMenuItem', {
        itemType: type,
        objectId: id,
        objectName: name
      });
    }

    function activateMenuItem() {
      $rootScope.$broadcast('openproject.layout.activateMenuItem');
    }

    /**
     * previousMenuItem
     *
     * Returns the menu item within the factories's container that has a title
     * alphabetically before the provided title. The considered menu items have
     * the type (css class) this factory is responsible for.
     *
     * Params
     *  * title: The string used for comparing.
     */

    function previousMenuItem(title) {
      var allItems     = getContainer().find('li'),
          previousElement = angular.element(allItems[allItems.length - 1]),
          i = allItems.length - 2;

      for (i; i >= 0; i--) {
        if ((title > previousElement.find('a').attr('title')) ||
            (previousElement.find('.' + type).length === 0))
        {
          return previousElement;
        }
        else {
          previousElement = angular.element(allItems[i]);
        }
      }
    }

    return {
      generateMenuItem: generateMenuItem,
      removeMenuItem: removeMenuItem,
      activateMenuItem: activateMenuItem,
      renameMenuItem: renameMenuItem,
      link: linkFn
    };
  };
};
