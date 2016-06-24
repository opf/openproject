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

describe('Query', () => {
  var Query;
  var query:any;

  beforeEach(angular.mock.module('openproject.filters'));
  beforeEach(angular.mock.inject(function (_Query_) {
    Query = _Query_;
  }));

  it('should exist', () => {
    expect(Query).to.exist;
  });

  it('should be a constructor function', () => {
    var queryData = {id: 1};
    expect(new Query(queryData)).to.exist;
    expect(new Query(queryData)).to.be.an('object');
  });

  describe('toParams, toUpdateParams', () => {
    beforeEach(() => {
      query = Factory.build('Query');
    });

    context('query is dirty', () => {
      beforeEach(() => {
        query.id = 1;
        query.dirty = true;
      });
      it('should contain accept_empty_query_fields as true', () => {
        expect(query.toParams())
          .to.have.property('accept_empty_query_fields')
          .and.equal(true);
        expect(query.toUpdateParams())
          .to.have.property('accept_empty_query_fields')
          .and.equal(true);
      });
    });

    context('query is dirty', () => {
      beforeEach(() => {
        query.id = 1;
        query.dirty = false;
      });
      it('should contain accept_empty_query_fields as true', () => {
        expect(query.toParams())
          .to.have.property('accept_empty_query_fields')
          .and.equal(false);
        expect(query.toUpdateParams())
          .to.have.property('accept_empty_query_fields')
          .and.equal(false);
      });
    });
  });

  describe('adding filters', () => {
    var filter;

    beforeEach(() => {
      query = Factory.build('Query', {filters: []});
      filter = Factory.build('Filter', {name: 'type_id'});
    });

    it('should augment filters with meta data when set via setFilters', () => {
      query.setFilters([filter]);

      expect(query.filters[0]).to.have.property('type')
        .and.equal('list_model');

      expect(query.filters[0]).to.have.property('modelName')
        .and.equal('type');
    });

    it('should augment filters with meta data when set via addFilter', () => {
      query.addFilter(filter.name, filter);

      expect(query.filters[0]).to.have.property('type')
        .and.equal('list_model');

      expect(query.filters[0]).to.have.property('modelName')
        .and.equal('type');
    });
  });

  describe('hasName', () => {
    beforeEach(() => {
      query = Factory.build('Query');
    });

    it('returns false if the query does not have a name', () => {
      expect(query.hasName()).to.be.false;
    });

    it('returns false if the query name equals "_"', () => {
      query.name = '_';
      expect(query.hasName()).to.be.false;
    });

    it('returns true if the query name is present and different from "_"', () => {
      query.name = 'abc';
      expect(query.hasName()).to.be.true;
    });
  });

  describe('isDefault', () => {
    it('returns true if the query name equals "_"', () => {
      query.name = '_';
      expect(query.isDefault()).to.be.true;
    });

    it('returns false if the query name is undefined', () => {
      query.name = undefined;
      expect(query.isDefault()).to.be.false;
    });

    it('returns false if the query name is any string', () => {
      query.name = 'so random';
      expect(query.isDefault()).to.be.false;
    });
  });

  describe('setDefaultFilter', () => {
    beforeEach(() => {
      query.setDefaultFilter();
    });

    it('sets a single filter', () => {
      expect(query.filters.length).to.equal(1);
    });

    it('filters for status: open', () => {
      var filter = query.filters[0];

      expect(filter.name).to.equal('status');
      expect(filter.operator).to.equal('o');
    });
  });
});
