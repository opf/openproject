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

declare var I18n:op.I18n;

describe('tablePagination Directive', function () {
  var compile:any, element:any, rootScope:any, scope:any, PaginationService:any, paginationOptions:any;

  beforeEach(angular.mock.module('openproject.workPackages.directives', 'openproject.services'));
  beforeEach(angular.mock.module('openproject.templates'));

  beforeEach(angular.mock.inject(function (_PaginationService_:any) {
    PaginationService = _PaginationService_;
  }));

  beforeEach(inject(function ($rootScope:any, wpTableMetadata:any, $compile:any) {
    var html;

    html = `
      <table-pagination icon-name="totalResults"
                        update-results="noteUpdateResultsCalled()">
      </table-pagination>'
    `;

    element = angular.element(html);
    rootScope = $rootScope;
    scope = $rootScope.$new();

    scope.noteUpdateResultsCalled = function() {
      scope.updateResultsCalled = true;
    };
    scope.setTotalResults = (num:string) => {
      wpTableMetadata.metadata.put({
        total: num
      });
      scope.$apply();
    };

    paginationOptions = sinon.stub(PaginationService, 'getPaginationOptions');
    paginationOptions.returns({ perPageOptions: [10, 100, 500, 1000],
                                perPage: 10,
                                page: 1,
                                maxVisiblePageOptions: 6,
                                optionsTruncationSize: 2 });

    compile = function () {
      $compile(element)(scope);
      scope.$apply();
    };
  }));

  describe('page ranges and links', function () {

    it('should display the correct page range', function () {
      var pageString = function () {
        return element.find('.pagination--range').text().trim();
      };

      compile();

      scope.setTotalResults(0);
      expect(pageString()).to.equal('');

      scope.setTotalResults(11);
      expect(pageString()).to.equal('(1 - 10/11)');

      scope.setTotalResults(663);
      expect(pageString()).to.equal('(1 - 10/663)');
    });

    describe('"next" link', function() {
      beforeEach(function() {
        scope.setTotalResults(115);
      });

      it('hidden on the last page', function() {
        paginationOptions.returns({ perPageOptions: [10, 100, 500, 1000],
                                    perPage: 10,
                                    page: 12,
                                    maxVisiblePageOptions: 6,
                                    optionsTruncationSize: 2 });
        compile();

        expect(element.find('.pagination--next-link').parent().hasClass('ng-hide')).to.be.true;
      });
    });

    it('should display correct number of page number links', function () {
      var numberOfPageNumberLinks = function () {
        return element.find('a[rel="next"]').length;
      };

      compile();

      scope.setTotalResults(1);
      expect(numberOfPageNumberLinks()).to.eq(1);

      scope.setTotalResults(11);
      expect(numberOfPageNumberLinks()).to.eq(2);

      scope.setTotalResults(59);
      expect(numberOfPageNumberLinks()).to.eq(6);

      scope.setTotalResults(101);
      expect(numberOfPageNumberLinks()).to.eq(7);
    });
  });

  describe('updateResults callback', function () {
    beforeEach(function() {
      scope.updateResultsCalled = false;
      compile();
      scope.setTotalResults(20);
    });

    it('calls the callback when showing a different page', function() {
      element.find('a[rel="next"]:first').click();

      expect(scope.updateResultsCalled).to.eq(true);
    });

    it('calls the callback when selecting a different per page option', function() {
      // click on first per-page anchor (current is not an anchor)
      element.find('.pagination--options a:eq(0)').click();

      expect(scope.updateResultsCalled).to.eq(true);
    });
  });

  describe('perPage options', function () {
    var t;

    beforeEach(function() {
      t = sinon.stub(I18n, 't');
      t.withArgs('js.label_per_page').returns('Per page:');
    });

    afterEach(inject(function() {
      (I18n.t as any).restore();
    }));

    describe('with no entries', function() {
      beforeEach(function() {
        compile();
        scope.setTotalResults(0);
      });

      it('should have no perPage options', function () {
        var perPageOptions = element.find('.pagination--options');

        expect(perPageOptions.text()).to.not.include('Per page:');
      });
    });

    describe('with few entries', function() {
      beforeEach(function() {
        compile();
        scope.setTotalResults(5);
      });

      it('should have no perPage options', function () {
        var perPageOptions = element.find('.pagination--options');

        expect(perPageOptions.text()).to.not.include('Per page:');
      });
    });

    describe('with multiple entries', function() {
      beforeEach(function() {
        compile();
        scope.setTotalResults(20);
      });

      it('should render perPage options', function () {
        var perPageOptions = element.find('.pagination--options');

        expect(perPageOptions.text()).to.include('Per page:');
      });
    });
  });
});
