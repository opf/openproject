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

/*jshint expr: true*/


import {QueryMenuService} from 'core-components/wp-query-menu/wp-query-menu.service';

describe('queryMenuItemFactory', function() {
  var menuContainer:any, element:any, document:any,
      $rootScope:ng.IRootScopeService, scope:ng.IScope,
      queryMenu:QueryMenuService, state:any = {}, stateParams:any = {};

  beforeEach(angular.mock.module('openproject.layout'));
  beforeEach(angular.mock.module('openproject.templates',
                    'openproject.services',
                    'openproject.uiComponents',
                    'openproject.models',
                    'openproject.api',
                    function($provide:ng.auto.IProvideService) {
    var configurationService:any = {};

    configurationService.isTimezoneSet = sinon.stub().returns(false);

    $provide.constant('ConfigurationService', configurationService);
  }));

  beforeEach(angular.mock.module('openproject.templates', function($provide:ng.auto.IProvideService) {
    // Mock check whether we are on a work_packages page
    state = { includes: function() { return true; } };
    $provide.value('$state', state);

    $provide.value('$stateParams', stateParams);
  }));

  beforeEach(inject(function(_$rootScope_:ng.IRootScopeService,
                             $compile:ng.ICompileService,
                             $document:ng.IDocumentService) {
    $rootScope = _$rootScope_;

    // set up html body
    const template = `
      <div id="main-menu-work-packages-wrapper">
        <a id="main-menu-work-packages" wp-query-menu>Work packages</a>
        <ul class="menu-children"></ul>'
      </div>
    `;
    element = angular.element(template);
    $compile(element)($rootScope);

    document = $document[0];
    var body = angular.element(document.body);
    body.append(element);
    menuContainer = element.find('ul.menu-children');
  }));

  beforeEach(inject(function(_queryMenu_:QueryMenuService) {
    queryMenu = _queryMenu_;
  }));

  afterEach(inject(function() {
    // The document does not seem to be cleaned up after each test instead each
    // test leaves additional DOM. Thus the tests are not independent.
    // Therefore we clean it by hand.
    element.remove();
  }));

  describe('#add for a query', function() {
    var menuItem:any, itemLink:any;
    var path = '/work_packages?query_id=1',
        title = 'Query',
        objectId = '1';

    var generateMenuItem = function() {
      queryMenu.add(title, path, objectId);

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

    describe('when the query id matches the query id of the state params', function() {
      beforeEach(inject(function() {
        stateParams['query_id'] = objectId;
        $rootScope.$apply();
      }));

      it('marks the new item as selected', function() {
        expect(itemLink.hasClass('selected')).to.be.true;
      });

      it('toggles the selected state on state change', function() {
        stateParams['query_id'] = null;
        $rootScope.$apply();
        expect(itemLink.hasClass('selected')).to.be.false;
      });
    });

    describe('when the query id is undefined', function(){
      beforeEach(inject(function() {
        stateParams['query_id'] = undefined;
        $rootScope.$apply();
      }));

      it('marks the new item as unselected', function() {
        expect(itemLink.hasClass('selected')).to.be.false;
      });

      it('toggles the selected state on state change', function() {
        stateParams['query_id'] = objectId;
        $rootScope.$apply();

        expect(itemLink.hasClass('selected')).to.be.true;
      });
    });
  });

  describe('#generateMenuItem for the work package index item', function() {
    var menuItem:any, itemLink:any;
    var path = '/work_packages',
        title = 'Work Packages',
        objectId:any = undefined;

    beforeEach(function() {
      queryMenu.add(title, path, objectId);
      $rootScope.$apply();

      menuItem = menuContainer.children('li');
      itemLink = menuItem.children('a');
      scope = itemLink.scope();
    });

    describe('on a work_package page', function() {

      describe('for an undefined query_id', function() {
        beforeEach(inject(function() {
          stateParams['query_id'] = undefined;
          $rootScope.$apply();
        }));

        it('marks the item as selected', function() {
          expect(itemLink.hasClass('selected')).to.be.false;
        });
      });

      describe('for a null query_id', function() {
        beforeEach(inject(function() {
          stateParams['query_id'] = null;
          $rootScope.$apply();
        }));

        it('marks the item as selected', function() {
          expect(itemLink.hasClass('selected')).to.be.false;
        });
      });

      describe('for an integer query_id', function() {
        beforeEach(inject(function() {
          stateParams['query_id'] = 1;
          $rootScope.$apply();
        }));

        it('does not mark the item as selected', function() {
          expect(itemLink.hasClass('selected')).to.be.false;
        });
      });

      describe('for a string query_id', function() {
        beforeEach(inject(function() {
          stateParams['query_id'] = "1";
          $rootScope.$apply();
        }));

        it('does not mark the item as selected', function() {
          expect(itemLink.hasClass('selected')).to.be.false;
        });
      });
    });

    describe('on a non-work package page', function() {
      beforeEach(function() {
        // Change mock for checking whether we are on a work_packages page
        state.includes = function() { return false; };
      });

      describe('for an undefined query_id', function() {
        beforeEach(inject(function() {
          stateParams['query_id'] = undefined;
          $rootScope.$apply();
        }));

        it('marks the item as selected', function() {
          expect(itemLink.hasClass('selected')).to.be.false;
        });
      });

      describe('for a null query_id', function() {
        beforeEach(inject(function() {
          stateParams['query_id'] = null;
          $rootScope.$apply();
        }));

        it('marks the item as selected', function() {
          expect(itemLink.hasClass('selected')).to.be.false;
        });
      });
    });
  });
});
