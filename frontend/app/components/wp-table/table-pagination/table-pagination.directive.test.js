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

describe('tablePagination Directive', function () {
  var compile, element, rootScope, scope, PaginationService, paginationOptions;

  beforeEach(angular.mock.module('openproject.workPackages.directives', 'openproject.services'));
  beforeEach(angular.mock.module('openproject.templates'));

  beforeEach(angular.mock.inject(function (_PaginationService_) {
    PaginationService = _PaginationService_;
  }));

  beforeEach(inject(function ($rootScope, $compile) {
    var html;

    html = '<table-pagination total-entries="tableEntries" icon-name="totalResults"' +
      ' update-results="noteUpdateResultsCalled()"></table-pagination>';

    element = angular.element(html);
    rootScope = $rootScope;
    scope = $rootScope.$new();

    scope.noteUpdateResultsCalled = function() {
      scope.updateResultsCalled = true;
    };
    scope.tableEntries = 11;

    paginationOptions = sinon.stub(PaginationService, 'getPaginationOptions');
    paginationOptions.returns({ perPageOptions: [10, 100, 500, 1000],
                                perPage: 10,
                                page: 1,
                                maxVisiblePageOptions: 6,
                                optionsTruncationSize: 2 });

    compile = function () {
      $compile(element)(scope);
      scope.$digest();
    };
  }));

  describe('page ranges and links', function () {

    it('should display the correct page range', function () {
      var pageString = function () {
        return element.find('.pagination--range').text().trim();
      };

      compile();

      scope.tableEntries = 0;
      scope.$apply();

      expect(pageString()).to.equal('');

      scope.tableEntries = 11;
      scope.$apply();

      expect(pageString()).to.equal('(1 - 10/11)');

      scope.tableEntries = 663;
      scope.$apply();

      expect(pageString()).to.equal('(1 - 10/663)');
    });

    describe('"next" link', function() {
      beforeEach(function() {
        scope.tableEntries = 115;
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
        return element.find('a[rel="next"]').size();
      };

      compile();

      scope.tableEntries = 1;
      scope.$apply();

      expect(numberOfPageNumberLinks()).to.eq(1);

      scope.tableEntries = 11;
      scope.$apply();
      expect(numberOfPageNumberLinks()).to.eq(2);

      scope.tableEntries = 59;
      scope.$apply();
      expect(numberOfPageNumberLinks()).to.eq(6);

      scope.tableEntries = 101;
      scope.$apply();
      expect(numberOfPageNumberLinks()).to.eq(8);
    });
  });

  describe('updateResults callback', function () {
    beforeEach(function() {
      scope.updateResultsCalled = false;
      compile();
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
      I18n.t.restore();
    }));

    describe('with no entries', function() {
      beforeEach(function() {
        scope.tableEntries = 0;
        compile();
      });

      it('should have no perPage options', function () {
        var perPageOptions = element.find('.pagination--options');

        expect(perPageOptions.text()).to.not.include('Per page:');
      });
    });

    describe('with entries', function() {
      beforeEach(function() {
        compile();
      });

      it('should render perPage options', function () {
        var perPageOptions = element.find('.pagination--options');

        expect(perPageOptions.text()).to.include('Per page:');
      });
    });
  });
});
