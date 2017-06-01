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

describe('sort link Directive', function() {
    var I18n, t, compile, element, scope, sortService;

    beforeEach(angular.mock.module('openproject.uiComponents'));
    beforeEach(angular.mock.module('openproject.templates', function($provide) {
      sortService = {};

      sortService.isDescending = sinon.stub().returns(false);
      sortService.getColumn = sinon.stub().returns('');

      $provide.constant('SortService', sortService);
    }));

    beforeEach(inject(function($rootScope, $compile, _I18n_) {
      var html = '<sort-link sort-attr="id" sort-func="sortFunc()">Id</sort-link>';

      scope = $rootScope.$new();

      scope.sortFunc = sinon.spy();

      compile = function() {
        element = $compile(html)(scope);
        scope.$digest();
      };

      I18n = _I18n_;
      t = sinon.stub(I18n, 't');

      t.withArgs('js.label_descending').returns('desc');
      t.withArgs('js.label_ascending').returns('down');
      t.withArgs('js.label_sorted_by').returns('sorted by');
      t.withArgs('js.label_sort_by').returns('sort by');
    }));

    afterEach(inject(function() {
      I18n.t.restore();
    }));

    var link;

    describe('inital state', function() {
      beforeEach(function() {
        compile();
        link = element.children();
      });

      it('should render a link', function() {
        expect(link.prop('tagName')).to.equal('A');
      });

      it('should render title', function() {
        expect(link.prop('title')).to.equal("sort by Id");
      });

      it('should set sort css', function() {
        var directiveScope = element.isolateScope();

        expect(directiveScope.sortDirection).to.empty;
      });

      describe('callback', function() {
        it('should call callback', function() {
          var directiveScope = element.isolateScope();

          directiveScope.sortFunc();

          expect(scope.sortFunc.calledOnce).to.be.true;
        });
      });
    });

    describe('changing sort arguments', function() {
      beforeEach(function() {
        sortService.getColumn = sinon.stub().returns('id');
        sortService.getDirection = sinon.stub().returns('desc');
        sortService.isDescending = sinon.stub().returns(false);
        compile();
        link = element.children();
      });

      it('should render title', function() {
        expect(link.prop('title')).to.equal("down sorted by Id");
      });

      it('should set sort css', function() {
        var directiveScope = element.isolateScope();

        expect(directiveScope.sortDirection).to.equal('asc');
      });
    });
});
