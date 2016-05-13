// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// ++

var expect = chai.expect;
declare var Factory:any;

describe('workPackageContextMenu', () => {
  var container;
  var contextMenu;
  var $rootScope;
  var stateParams = {};
  var ngContextMenu;

  beforeEach(angular.mock.module('ng-context-menu',
    'openproject',
    'openproject.api',
    'openproject.workPackages',
    'openproject.models',
    'openproject.layout',
    'openproject.services',
    'openproject.templates'));

  beforeEach(angular.mock.module('openproject.templates', ($provide) => {
    var configurationService = {
      isTimezoneSet: sinon.stub().returns(false),
      accessibilityModeEnabled: sinon.stub().returns(false)
    };

    $provide.constant('ConfigurationService', configurationService);
    $provide.constant('$stateParams', stateParams);
  }));

  beforeEach(() => {
    container = angular.element('<div></div>');
  });

  beforeEach(angular.mock.inject((_$rootScope_, _ngContextMenu_, $templateCache) => {
    $rootScope = _$rootScope_;
    ngContextMenu = _ngContextMenu_;

    var template = $templateCache
      .get('/components/context-menus/wp-context-menu/wp-context-menu.service.html');
    $templateCache.put('work_package_context_menu.html', [200, template, {}]);

    contextMenu = ngContextMenu({
      controller: 'WorkPackageContextMenuController',
      controllerAs: 'contextMenu',
      container: container,
      templateUrl: 'work_package_context_menu.html'
    });

    contextMenu.open({x: 0, y: 0});
  }));

  describe('when the context menu context contains one work package', () => {
    var I18n;
    var actions = ['edit', 'move'];
    var actionLinks = {
      update: '/work_packages/123/edit',
      move: '/work_packages/move/new?ids%5B%5D=123',
    };
    var workPackage = Factory.build('PlanningElement');
    workPackage.$source = { _links: actionLinks };
    workPackage.$links = actionLinks;

    var directListElements;

    beforeEach(angular.mock.inject((_I18n_) => {
      I18n = _I18n_;
      sinon.stub(I18n, 't').withArgs('js.button_' + actions[0]).returns('anything');
    }));
    afterEach(angular.mock.inject(() => {
      I18n.t.restore();
    }));

    beforeEach(() => {
      $rootScope.rows = [];
      $rootScope.row = {object: workPackage};

      $rootScope.$digest();

      directListElements = container.find('.dropdown-menu > li:not(.folder)');
    });

    it('lists link tags for any permitted action', () =>{
      expect(directListElements.length).to.equal(4);
    });

    it('assigns a css class named by the action', () =>{
      expect(directListElements[2].className).to.equal(actions[0]);
    });

    it('adds an icon from the icon fonts to each list container', () => {
      expect(container.find('.' + actions[0] +' a i').attr('class')).to.include('icon-' + actions[0]);
    });

    it('sets the checked property of the row within the context to true', () => {
      expect($rootScope.row.checked).to.be.true;
    });

    describe('when delete is permitted on a work package', () => {
      var actionLinks = {
        'delete': '/work_packages/bulk',
      };
      var workPackage = Factory.build('PlanningElement');
      workPackage.$source = { _links: actionLinks };
      workPackage.$links = actionLinks;

      beforeEach(() => {
        $rootScope.rows = [];
        $rootScope.row = {object: workPackage};
        $rootScope.$digest();

        directListElements = container.find('.dropdown-menu > li:not(.folder)');
      });
    });
  });
});
