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

import {QueryColumn} from '../../wp-query/query-column';
describe('columnContextMenu', function() {
  var container:any, contextMenu:any, wpTableColumns:any, wpTableGroupBy:any, wpTableSortBy:any, $rootScope:any, scope:any, ngContextMenu:any;

  beforeEach(angular.mock.module('ng-context-menu',
                    'openproject.workPackages',
                    'openproject.workPackages.controllers',
                    'openproject.models',
                    'openproject.api',
                    'openproject.layout',
                    'openproject.templates'));

  beforeEach(angular.mock.module('openproject.services', function($provide:any) {
    wpTableGroupBy = {
      isGroupable: (column: QueryColumn) => true,
      isCurrentlyGroupedBy: (column: QueryColumn) => false
    }

    wpTableSortBy = {
      isSortable: (column: QueryColumn) => true
    }

    wpTableColumns = {
      isFirst: (column: QueryColumn) => false,
      isLast: (column: QueryColumn) => false,
      previous: (column: QueryColumn) => null
    }

    $provide.constant('wpTableGroupBy', wpTableGroupBy);
    $provide.constant('wpTableSortBy', wpTableSortBy);
    $provide.constant('wpTableColumns', wpTableColumns);
  }));

  beforeEach(function() {
    var html = '<div></div>';
    container = angular.element(html);
  });

  beforeEach(inject(function(_$rootScope_:any, _ngContextMenu_:any, $templateCache:any) {
    $rootScope = _$rootScope_;
    ngContextMenu = _ngContextMenu_;

    var template = $templateCache.get(
      '/components/context-menus/column-context-menu/column-context-menu.template.html');

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
    var column        = { name: 'Status' },
        anotherColumn = { name: 'Subject' },
        columns       = [column, anotherColumn]

    beforeEach(function() {
      $rootScope.column = column;
      $rootScope.$digest();

      scope = container.children().scope();
    });

    it('fetches the column from the context handle context', function() {
      expect($rootScope.column).to.have.property('name').and.contain(column.name);
    });

    describe('and the group by option is clicked', function() {
      var spy:any;

      beforeEach(function() {
        spy = sinon.spy();
        wpTableGroupBy['setBy'] = spy;

        scope.groupBy();
      });

      it('calls the appropriate state', function() {
        expect(spy).to.have.been.calledWith(column);
      });
    });

    describe('and "move column right" is clicked', function() {
      var spy:any;

      beforeEach(function() {
        spy = sinon.spy();
        wpTableColumns['shift'] = spy;

        scope.moveRight();
      });

      it('calls the appropriate state', function() {
        expect(spy).to.have.been.calledWith(column, 1);
      });
    });

    describe('and "move column left" is clicked', function() {
      var spy:any;

      beforeEach(function() {
        spy = sinon.spy();
        wpTableColumns['shift'] = spy;

        scope.moveLeft();
      });

      it('calls the appropriate state', function() {
        expect(spy).to.have.been.calledWith(column, -1);
      });
    });

    describe('and "Sort ascending" is clicked', function() {
      var spy:any;

      beforeEach(function() {
        spy = sinon.spy();
        wpTableSortBy['addAscending'] = spy;

        scope.sortAscending();
      });

      it('calls the appropriate state', function() {
        expect(spy).to.have.been.calledWith(column);
      });
    });

    describe('and "Sort descending" is clicked', function() {
      var spy:any;

      beforeEach(function() {
        spy = sinon.spy();
        wpTableSortBy['addDescending'] = spy;

        scope.sortDescending();
      });

      it('calls the appropriate state', function() {
        expect(spy).to.have.been.calledWith(column);
      });
    });

    describe('and "Hide column" is clicked', function() {
      var spy:any;

      beforeEach(function() {
        spy = sinon.spy();
        wpTableColumns['removeColumn'] = spy;
        sinon.stub(wpTableColumns, 'previous');

        scope.hideColumn();
      });

      it('calls the appropriate state', function() {
        expect(spy).to.have.been.calledWith(column);
      });
    });

    describe('and "Insert columns" is clicked', function() {
      var activateFn:any, columnsModal:any;

      beforeEach(inject(function(_columnsModal_:any) {
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
