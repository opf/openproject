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

describe('QueryService', function() {

  var QueryService;
  beforeEach(module('openproject.services', 'openproject.models'));

  beforeEach(inject(function(_QueryService_){
    QueryService = _QueryService_;
  }));

  describe('query setup', function () {

    beforeEach(function() {
      queryData = {
        group_by: 'type',
        display_sums: 1,
        filters: {
          type_id: {
            operator: '~',
            values: ['Bug', 'Feature']
          }
        }
      };

      query = QueryService.initQuery(null, queryData);
    });

    it('should set query.groupBy', function() {
      expect(query.groupBy).to.equal(queryData.group_by);
    });

    it('should set query.displaySums', function() {
      expect(query.displaySums).to.equal(queryData.display_sums);
    });

    describe('filters', function() {
      // TODO mock promise-returning `getAvailableWorkPackageFilters` method

      it('should load the available filters');

      it('should assign filters to the query');
    });
  });

});
