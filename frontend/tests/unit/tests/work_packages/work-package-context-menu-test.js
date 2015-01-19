//-- copyright
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
//++

/*jshint expr: true*/

describe('workPackageContextMenu', function() {
  var container, contextMenu, $rootScope, stateParams, ngContextMenu;
  stateParams = {};

  beforeEach(module('ng-context-menu',
                    'openproject.api',
                    'openproject.workPackages',
                    'openproject.models',
                    'openproject.layout',
                    'openproject.services',
                    'openproject.templates'));

  beforeEach(module('openproject.templates', function($provide) {
    var configurationService = {};

    configurationService.isTimezoneSet = sinon.stub().returns(false);

    $provide.constant('ConfigurationService', configurationService);
    $provide.constant('$stateParams', stateParams);
  }));

  beforeEach(function() {
    var html = '<div></div>';
    container = angular.element(html);
  });

  beforeEach(inject(function(_$rootScope_, _ngContextMenu_, $templateCache) {
    $rootScope = _$rootScope_;
    ngContextMenu = _ngContextMenu_;

    var template = $templateCache
      .get('/templates/work_packages/menus/work_package_context_menu.html');
    $templateCache.put('work_package_context_menu.html', [200, template, {}]);

    contextMenu = ngContextMenu({
      controller: 'WorkPackageContextMenuController',
      controllerAs: 'contextMenu',
      container: container,
      templateUrl: 'work_package_context_menu.html'
    });

    contextMenu.open({x: 0, y: 0});
  }));

  describe('when the context menu context contains one work package', function() {
    var I18n;
    var actions = ['edit', 'move'],
        actionLinks = {
          edit: '/work_packages/123/edit',
          move: '/work_packages/move/new?ids%5B%5D=123',
        },
        workPackage = Factory.build('PlanningElement', {
          _actions: actions,
          _links: actionLinks
        });
    var directListElements;

    beforeEach(inject(function(_I18n_) {
      I18n = _I18n_;
      sinon.stub(I18n, 't').withArgs('js.button_' + actions[0]).returns('anything');
    }));
    afterEach(inject(function() {
      I18n.t.restore();
    }));

    beforeEach(function() {
      $rootScope.rows = [];
      $rootScope.row = {object: workPackage};

      $rootScope.$digest();

      directListElements = container.find('.dropdown-menu > li:not(.folder)');
    });

    it('lists link tags for any permitted action', function(){
      expect(directListElements.length).to.equal(3);
    });

    it('assigns a css class named by the action', function(){
      expect(directListElements[1].className).to.equal(actions[0]);
    });

    it('adds an icon from the icon fonts to each list container', function() {
      expect(container.find('.' + actions[0] +' a i').attr('class')).to.include('icon-' + actions[0]);
    });

    xit('translates the action name', function() {
      expect(container.find('.' + actions[0] +' a i').contents()).to.equal('anything');
      // TODO find out how to stub I18n.t inside directive
    });

    it('sets the checked property of the row within the context to true', function() {
      expect($rootScope.row.checked).to.be.true;
    });

    describe('when delete is permitted on a work package', function() {
      var actions = ['delete'],
          actionLinks = {
            delete: '/work_packages/bulk',
          },
          workPackage = Factory.build('PlanningElement', {
            _actions: actions,
            _links: actionLinks
          });

      beforeEach(function() {
        $rootScope.rows = [];
        $rootScope.row = {object: workPackage};
        $rootScope.$digest();

        directListElements = container.find('.dropdown-menu > li:not(.folder)');
      });

      xit('displays a link triggering deleteWorkPackages within the scope', function() {
        expect(directListElements.find('a:has(i.icon-delete)').attr('ng-click')).to.equal('deleteWorkPackages()');
      });
    });
  });

  xdescribe('when the context menu context contains multiple work packages', function() {

  });

});
