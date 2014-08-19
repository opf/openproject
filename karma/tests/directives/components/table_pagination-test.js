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

describe('tablePagination Directive', function () {
  var compile, element, rootScope, scope;

  beforeEach(angular.mock.module('openproject.uiComponents', 'openproject.services'));
  beforeEach(module('templates'));

  beforeEach(inject(function ($rootScope, $compile, _I18n_) {
    var html, I18n, t;;
    html = '<table-pagination total-entries="tableEntries" icon-name="totalResults"></table-pagination>';

    element = angular.element(html);
    rootScope = $rootScope;
    scope = $rootScope.$new();
    I18n = _I18n_;

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
      var range = element.find('.range');

      expect(range.text()).to.equal('');

      scope.tableEntries = 11;
      scope.$apply();
      expect(range.text()).to.equal('(1 - 10/11)');

      scope.tableEntries = 663;
      scope.$apply();
      expect(range.text()).to.equal('(1 - 10/663)');
    });

    it('should display correct number of page number links', function () {
      var numberOfPageNumberLinks = function () {
        return element.find('a.page-no').size();
      };

      expect(numberOfPageNumberLinks()).to.eq(0);

      scope.tableEntries = 11;
      scope.$apply();
      expect(numberOfPageNumberLinks()).to.eq(1);

      scope.tableEntries = 59;
      scope.$apply();
      expect(numberOfPageNumberLinks()).to.eq(5);

      scope.tableEntries = 101;
      scope.$apply();
      expect(numberOfPageNumberLinks()).to.eq(10);
    });
  });

  describe('perPage options', function () {
    beforeEach(function() {
      t = sinon.stub(I18n, 't');
      t.withArgs('js.label_per_page').returns('Per page:');
      compile();
    });

    afterEach(inject(function() {
      I18n.t.restore();
    }));

    it('should always render perPage options', function () {
      var perPageOptions = element.find('span.per_page_options');

      expect(perPageOptions.text()).to.include('Per page:');
    });
  });
});
