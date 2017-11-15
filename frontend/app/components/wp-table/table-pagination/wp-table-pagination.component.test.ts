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

import {BehaviorSubject} from 'rxjs';

describe('wpTablePagination Directive', function () {
  var compile:any, element:any, rootScope:any, scope:any, PaginationService:any, paginationOptions:any;
  let state:any;
  let subject:any;
  var wpTablePagination:any;
  var I18n:op.I18n;

  beforeEach(angular.mock.module('openproject.workPackages.directives'));
  beforeEach(angular.mock.module('openproject.templates'));
  beforeEach(angular.mock.module('openproject.services', function($provide:any) {
    wpTablePagination = {
      observeOnScope: function(scope:ng.IScope) {
        return subject;
      }
    };

    $provide.constant('wpTablePagination', wpTablePagination);
  }));

  beforeEach(angular.mock.inject(function (_PaginationService_:any, _I18n_:op.I18n) {
    PaginationService = _PaginationService_;
    I18n = _I18n_;
  }));

  let setTotalResults = (total:number) => {
    let current = subject.getValue();

    pushState(total, current.current.perPage, current.current.page);
  };

  let pushState = (total:number, perPage:number, page:number) => {
    subject.next({
      total: total,
      current: {
        perPage: perPage,
        page: page
      }
    });
    scope.$apply();
  };

  beforeEach(inject(function ($rootScope:any, $compile:any) {
    var html;

    html = `
      <wp-table-pagination> </wp-table-pagination>'
    `;

    element = angular.element(html);
    rootScope = $rootScope;
    scope = $rootScope.$new();

    state = {
      total: 100,
      current: {
        perPage: 10,
        page: 1
      }
    };
    subject = new BehaviorSubject(state);

    sinon.stub(PaginationService, 'loadPerPageOptions');
    sinon.stub(PaginationService, 'getPerPageOptions', () => [10, 100, 500, 1000]);

    compile = function () {
      subject = new BehaviorSubject(state);
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

      setTotalResults(0);
      expect(pageString()).to.equal('');

      setTotalResults(11);
      expect(pageString()).to.equal('(1 - 10/11)');

      setTotalResults(663);
      expect(pageString()).to.equal('(1 - 10/663)');
    });

    describe('"next" link', function() {
      it('hidden on the last page', function() {
        state = {
          total: 11,
          current: {
            perPage: 10,
            page: 2
          }
        };
        compile();


        expect(element.find('.pagination--next-link').parent().hasClass('ng-hide')).to.be.true;
      });
    });

    it('should display correct number of page number links', function () {
      var numberOfPageNumberLinks = function () {
        return element.find('a[rel="next"]').length;
      };

      compile();

      setTotalResults(1);
      expect(numberOfPageNumberLinks()).to.eq(1);

      setTotalResults(11);
      expect(numberOfPageNumberLinks()).to.eq(2);

      setTotalResults(59);
      expect(numberOfPageNumberLinks()).to.eq(6);

      setTotalResults(101);
      expect(numberOfPageNumberLinks()).to.eq(7);
    });
  });

  describe('updating the state', function () {
    let updateFromObject:any;

    beforeEach(function() {
      compile();
      setTotalResults(20);

      updateFromObject = sinon.spy();
      wpTablePagination['updateFromObject'] = updateFromObject;
    });

    it('when showing a different page', function() {

      element.find('a[rel="next"]:first').click();

      expect(updateFromObject).to.have.been.calledWith({page: 2});
    });

    it('when selecting a different per page option', function() {
      // click on first per-page anchor (current is not an anchor)
      element.find('.pagination--options a:eq(0)').click();

      expect(updateFromObject).to.have.been.calledWith({page: 1, perPage: 100});
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
        setTotalResults(0);
      });

      it('should have no perPage options', function () {
        var perPageOptions = element.find('.pagination--options');

        expect(perPageOptions.text()).to.not.include('Per page:');
      });
    });

    describe('with few entries', function() {
      beforeEach(function() {
        compile();
        setTotalResults(1);
      });

      it('should have no perPage options', function () {
        var perPageOptions = element.find('.pagination--options');

        expect(perPageOptions.text()).to.not.include('Per page:');
      });
    });

    describe('with multiple entries', function() {
      beforeEach(function() {
        compile();
        setTotalResults(20);
      });

      it('should render perPage options', function () {
        var perPageOptions = element.find('.pagination--options');

        expect(perPageOptions.text()).to.include('Per page:');
      });
    });
  });
});
