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

describe('tablePagination Directive', function () {
  var compile, element, rootScope, scope;

  beforeEach(angular.mock.module('openproject.uiComponents', 'openproject.services'));
  beforeEach(module('openproject.templates'));

  beforeEach(inject(function ($rootScope, $compile, _I18n_) {
    var html, I18n, t;
    html = '<table-pagination total-entries="tableEntries" icon-name="totalResults" update-results="noteUpdateResultsCalled()"></table-pagination>';

    element = angular.element(html);
    rootScope = $rootScope;
    scope = $rootScope.$new();
    I18n = _I18n_;

    scope.noteUpdateResultsCalled = function() {
      scope.updateResultsCalled = true;
    };

    compile = function () {
      $compile(element)(scope);
      scope.$digest();
    };
  }));

  describe('page ranges and links', function () {
    beforeEach(function() {
      compile();
    });

    it('should display the correct page range', function () {
      var range = element.find('.pagination--range');

      expect(range.text()).to.equal('(0 - 0/0)');
      expect(element.find(".pagination--next-link").parent().hasClass("ng-hide")).to.be.true;

      scope.tableEntries = 11;
      scope.$apply();
      expect(range.text()).to.equal('(1 - 10/11)');

      scope.tableEntries = 663;
      scope.$apply();
      expect(range.text()).to.equal('(1 - 10/663)');
    });

    it('should display the "next" link correctly', function() {
      scope.tableEntries = 115;
      scope.$apply();
      // should be 12 pages, in 10 iterations we will get to the penultimate page
      // this also covers the case where you clink on the 9th and "next" is  hidden
      for (var i = 0; i <= 9; i++) {
        element.find(".pagination--next-link").click();
        expect(element.find(".pagination--next-link").parent().hasClass("ng-hide")).to.be.false;
      }

      //on the last page now, next should be hidden
      element.find(".pagination--next-link").click();
      expect(element.find(".pagination--next-link").parent().hasClass("ng-hide")).to.be.true;
    });

    it('should display correct number of page number links', function () {
      var numberOfPageNumberLinks = function () {
        return element.find('a[rel="next"]').size();
      };

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

    it('calls the callback when seleceting a different per page option', function() {
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
      compile();
    });

    afterEach(inject(function() {
      I18n.t.restore();
    }));

    it('should always render perPage options', function () {
      var perPageOptions = element.find('.pagination--options');

      expect(perPageOptions.text()).to.include('Per page:');
    });
  });
});
