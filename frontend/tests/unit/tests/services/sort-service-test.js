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

describe('SortService', function() {

  var SortService;

  beforeEach(module('openproject.services'));

  beforeEach(inject(function(_SortService_){
    SortService = _SortService_;
  }));

  describe('#setDirection', function() {
    describe('invalid parameter', function() {
      it('throws error', function() {
        expect(SortService.setDirection).to.throw(Error, /Parameter does not match/);
      });
    });

    describe('AngularJS sort operator', function() {
      beforeEach(function() {
        SortService.setDirection('-');
      });

      it('sets direction descending', function() {
        expect(SortService.getDirection()).to.equal('desc');
      });
    });

  });

  describe('#isDescending', function() {
    it('sort is descending', function() {
      expect(SortService.isDescending()).to.be.false;
    });

    describe('set sort direction to descending', function() {
      beforeEach(function() {
        SortService.setDirection('desc');
      });

      it('sort is descending', function() {
        expect(SortService.isDescending()).to.be.true;
      });
    });
  });

  describe('#getSortParam', function() {
    beforeEach(function() {
      SortService.setColumn('id');
    });

    it('is valid sort param', function() {
      expect(SortService.getSortParam()).to.equal('id:asc');
    });

    describe('set sort direction to descending', function() {
      beforeEach(function() {
        SortService.setDirection('desc');
      });

      it('is valid sort param', function() {
        expect(SortService.getSortParam()).to.equal('id:desc');
      });
    });
  });
});
