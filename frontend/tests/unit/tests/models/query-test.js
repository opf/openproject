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

describe('Query', function() {

  var Query, query;

  beforeEach(module('openproject.models'));
  beforeEach(inject(function(_Query_) {
    Query = _Query_;
  }));

  it('should exist', function() {
    expect(Query).to.exist;
  });

  it('should be a constructor function', function() {
    var queryData = { id: 1 };
    expect(new Query(queryData)).to.exist;
    expect(new Query(queryData)).to.be.an('object');
  });

  describe('toParams, toUpdateParams', function() {
    beforeEach(function() {
      query = Factory.build('Query');
    });

    context('query is dirty', function() {
      beforeEach(function() {
        query.id = 1;
        query.dirty = true;
      });
      it("should contain accept_empty_query_fields as true", function() {
        expect(query.toParams())
          .to.have.property('accept_empty_query_fields')
          .and.equal(true);
        expect(query.toUpdateParams())
          .to.have.property('accept_empty_query_fields')
          .and.equal(true);
      });
    });

    context('query is dirty', function() {
      beforeEach(function() {
        query.id = 1;
        query.dirty = false;
      });
      it("should contain accept_empty_query_fields as true", function() {
        expect(query.toParams())
          .to.have.property('accept_empty_query_fields')
          .and.equal(false);
        expect(query.toUpdateParams())
          .to.have.property('accept_empty_query_fields')
          .and.equal(false);
      });
    });
  });

  describe('adding filters', function(){
    var filter;

    beforeEach(function(){
      query = Factory.build('Query', {filters: []});
      filter = Factory.build('Filter', {name: 'type_id'});
    });

    it('should augment filters with meta data when set via setFilters', function() {
      query.setFilters([filter]);

      expect(query.filters[0]).to.have.property('type')
                              .and.equal('list_model');

      expect(query.filters[0]).to.have.property('modelName')
                              .and.equal('type');
    });

    it('should augment filters with meta data when set via addFilter', function() {
      query.addFilter(filter.name, filter);

      expect(query.filters[0]).to.have.property('type')
                              .and.equal('list_model');

      expect(query.filters[0]).to.have.property('modelName')
                              .and.equal('type');
    });
  });

  describe('hasName', function() {
    beforeEach(function() {
      query = Factory.build('Query');
    });

    it('returns false if the query does not have a name', function() {
      expect(query.hasName()).to.be.false;
    });

    it('returns false if the query name equals "_"', function() {
      query.name = '_';
      expect(query.hasName()).to.be.false;
    });

    it('returns true if the query name is present and different from "_"', function() {
      query.name = 'abc';
      expect(query.hasName()).to.be.true;
    });
  });

  describe('isDefault', function() {
    it('returns true if the query name equals "_"', function() {
      query.name = '_';
      expect(query.isDefault()).to.be.true;
    });

    it('returns false if the query name is undefined', function() {
      query.name = undefined;
      expect(query.isDefault()).to.be.false;
    });

    it('returns false if the query name is any string', function() {
      query.name = 'so random';
      expect(query.isDefault()).to.be.false;
    });
  });

  describe('setDefaultFilter', function() {
    beforeEach(function() {
      query.setDefaultFilter();
    });

    it('sets a single filter', function() {
      expect(query.filters.length).to.equal(1);
    });

    it('filters for status: open', function() {
      var filter = query.filters[0];

      expect(filter.name).to.equal('status_id');
      expect(filter.operator).to.equal('o');
    });
  });
});
