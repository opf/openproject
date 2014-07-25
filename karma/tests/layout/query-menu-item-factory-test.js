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


describe('queryMenuItemFactory', function() {
  var menuContainer, document, menuItemPath = '/templates/layout/menu_item.html',
      $rootScope, scope,
      queryMenuItemFactory, stateParams = {};

  beforeEach(angular.mock.module('openproject.layout'));
  beforeEach(module('templates', 'openproject.services', 'openproject.models', 'openproject.api'));

  beforeEach(module('templates', function($provide) {
    $provide.value('$stateParams', stateParams);
  }));

  beforeEach(inject(function(_$rootScope_, $document, $templateCache) {
    $rootScope = _$rootScope_;

    // set up html body
    var template = '<div id="main-menu-work-packages-wrapper"></div>' +
                   '<ul class="menu-children"></ul>';
    menuContainer = angular.element(template);
    document = $document[0];
    var body = angular.element(document.body);
    body.append(menuContainer);
  }));

  beforeEach(inject(function(_queryMenuItemFactory_) {
    queryMenuItemFactory = _queryMenuItemFactory_;
  }));


  describe('#generateMenuItem', function() {
    var menuItem, itemLink;
    var path = '/work_packages?query_id=1',
        title = 'Query',
        objectId = 1;

    var generateMenuItem = function() {
      queryMenuItemFactory.generateMenuItem(title, path, objectId);
      $rootScope.$apply();

      menuItem = menuContainer.children('li');
      itemLink = menuItem.children('a');
      scope = itemLink.scope();
    };

    beforeEach(generateMenuItem);

    it ('adds a query menu item', function() {
      expect(menuItem).to.have.length(1);
    });

    it('assigns the item type as class', function() {
      expect(itemLink.hasClass('query-menu-item')).to.be.true;
    });

    it('applies the query menu item link function', function() {
      expect(scope.objectId).to.equal(objectId);
    });

    describe('when the query id matches the query id of the state params', function() {
      beforeEach(inject(function($timeout) {
        stateParams.query_id = objectId;
        $timeout.flush();
      }));

      it('marks the new item as selected', function() {
        expect(itemLink.hasClass('selected')).to.be.true;
      });

      it('toggles the selected state on state change', function() {
        stateParams.query_id = null;
        $rootScope.$broadcast('$stateChangeSuccess');

        expect(itemLink.hasClass('selected')).to.be.false;
      });
    });
  });
});
