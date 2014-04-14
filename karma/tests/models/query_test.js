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

describe('Query', function() {

  var Query;

  beforeEach(module('openproject.models'));
  beforeEach(inject(function(_Query_) {
    Query = _Query_;
  }));

  it('should exist', function() {
    expect(Query).to.exist;
  });

  it('should be a constructor function', function() {
    expect(new Query()).to.exist;
    expect(new Query()).to.be.an('object');
  });

  describe('adding filters', function(){
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


});
