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

/*jshint expr: true*/

describe('columnContextMenu Directive', function() {
  var compile, element, rootScope, scope;

  beforeEach(angular.mock.module('openproject.workPackages.directives'));
  beforeEach(module('templates', 'openproject.models'));

  beforeEach(inject(function($rootScope, $compile, _ContextMenuService_) {
    var html;
    html = '<column-context-menu></column-context-menu>';

    element = angular.element(html);
    rootScope = $rootScope;
    scope = $rootScope.$new();
    ContextMenuService = _ContextMenuService_;

    compile = function() {
      $compile(element)(scope);
      scope.$digest();
    };
  }));

  describe('element', function() {
    beforeEach(function() {
      compile();
    });

    it('should render a surrounding div', function() {
      expect(element.prop('tagName')).to.equal('DIV');
    });

  });

  describe('when the context menu handler of a column is clicked', function() {
    var I18n,
        QueryService,
        query = Factory.build('Query');
    var column = { name: 'status', title: 'Status' },
        anotherColumn = { name: 'subject', title: 'Subject' },
        columns = [column, anotherColumn];
    var directiveScope;

    beforeEach(inject(function(_QueryService_) {
      QueryService = _QueryService_;
      sinon.stub(QueryService, 'getQuery').returns(query);
    }));
    afterEach(inject(function() {
      QueryService.getQuery.restore();
    }));

    beforeEach(function() {
      compile();

      ContextMenuService.setContext({ column: column, columns: columns });
      ContextMenuService.open('columnContextMenu');
      scope.$apply();

      directiveScope = element.children().scope();
    });

    it('fetches the column from the context handle context', function() {
      expect(directiveScope.column).to.have.property('name').and.contain(column.name);
    });

    describe('and the group by option is clicked', function() {
      beforeEach(function() {
        directiveScope.groupBy(column.name);
      });

      it('changes the query group by', function() {
        expect(query.groupBy).to.equal(column.name);
      });
    });

    describe('and "move column right" is clicked', function() {
      beforeEach(function() {
        directiveScope.moveRight(column.name);
      });

      it('moves the column right', function() {
        expect(columns[1]).to.equal(column);
      });
    });
  });
});
