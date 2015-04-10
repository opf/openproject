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

describe('columnContextMenu', function() {
  var container, contextMenu, $rootScope, scope, stateParams, ngContextMenu;
  stateParams = {};

  beforeEach(module('ng-context-menu',
                    'openproject.workPackages',
                    'openproject.workPackages.controllers',
                    'openproject.models',
                    'openproject.api',
                    'openproject.layout',
                    'openproject.services',
                    'openproject.templates'));

  beforeEach(module('openproject.templates', function($provide) {
    var configurationService = {};

    configurationService.isTimezoneSet = sinon.stub().returns(false);

    $provide.constant('$stateParams', stateParams);
    $provide.constant('ConfigurationService', configurationService);
  }));

  beforeEach(function() {
    var html = '<div></div>';
    container = angular.element(html);
  });

  beforeEach(inject(function(_$rootScope_, _ngContextMenu_, $templateCache) {
    $rootScope = _$rootScope_;
    ngContextMenu = _ngContextMenu_;

    var template = $templateCache.get('/templates/work_packages/menus/column_context_menu.html');
    $templateCache.put('column_context_menu.html', [200, template, {}]);

    contextMenu = ngContextMenu({
      controller: 'ColumnContextMenuController',
      controllerAs: 'contextMenu',
      container: container,
      templateUrl: 'column_context_menu.html'
    });

    contextMenu.open({x: 0, y: 0});
  }));

  describe('when the context menu handler of a column is clicked', function() {
    var I18n, QueryService;
    var column        = { name: 'status', title: 'Status' },
        anotherColumn = { name: 'subject', title: 'Subject' },
        columns       = [column, anotherColumn],
        query         = Factory.build('Query', { columns: columns });
    var directiveScope;

    beforeEach(inject(function(_QueryService_) {
      QueryService = _QueryService_;
      sinon.stub(QueryService, 'getQuery').returns(query);
    }));
    afterEach(inject(function() {
      QueryService.getQuery.restore();
    }));

    beforeEach(function() {
      $rootScope.column = column;
      $rootScope.columns = columns;
      $rootScope.$digest();

      scope = container.children().scope();
    });

    it('fetches the column from the context handle context', function() {
      expect($rootScope.column).to.have.property('name').and.contain(column.name);
    });

    describe('and the group by option is clicked', function() {
      beforeEach(function() {
        scope.groupBy(column.name);
      });

      it('changes the query group by', function() {
        expect(query.groupBy).to.equal(column.name);
      });
    });

    describe('and "move column right" is clicked', function() {
      beforeEach(function() {
        scope.moveRight(column.name);
      });

      it('moves the column right', function() {
        expect(columns[1]).to.equal(column);
      });
    });

    describe('and "Sort ascending" is clicked', function() {
      var Sortation;

      beforeEach(inject(function(_Sortation_) {
        Sortation = _Sortation_;
        query.sortation = new Sortation();
        scope.sortAscending(column.name);
      }));

      it('updates the query sortation', function() {
        expect(query.sortation.getPrimarySortationCriterion()).to.deep.equal({ field: column.name, direction: 'asc' });
      });
    });

    describe('and "Hide column" is clicked', function() {
      beforeEach(function() {
        scope.hideColumn(column.name);
      });

      it('removes the column from the query columns', function() {
        expect(query.columns).to.not.include(column);
      });
    });

    describe('and "Insert columns" is clicked', function() {
      var activateFn, columnsModal;

      beforeEach(inject(function(_columnsModal_) {
        columnsModal = _columnsModal_;
        activateFn = sinon.stub(columnsModal, 'activate');
      }));
      afterEach(inject(function() {
        columnsModal.activate.restore();
      }));

      beforeEach(function() {
        scope.insertColumns();
      });

      it('opens the columns dialog', function() {
        expect(activateFn).to.have.been.called;
      });
    });

  });
});
