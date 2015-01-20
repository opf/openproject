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

describe('UrlParamsHelper', function() {
  var UrlParamsHelper, Query, PathHelper;

  beforeEach(module('openproject.helpers', 'openproject.models'));
  beforeEach(inject(function(_UrlParamsHelper_, _Query_, _PathHelper_) {
    UrlParamsHelper = _UrlParamsHelper_;
    Query = _Query_;
    PathHelper = _PathHelper_;
  }));

  describe('buildQueryString', function() {
    var params = {
      ids: [1, 2, 3],
      str: '@#$%'
    };
    var queryString;

    beforeEach(function() {
      queryString = UrlParamsHelper.buildQueryString(params);
    });

    it('concatenates propertys with \'&\'', function() {
      expect(queryString.split('&')).to.have.length(4);
    });

    it('escapes special characters', function() {
      expect(queryString).not.to.include('@');
    });
  });

  describe('encodeQueryJsonParams', function(){
    var query;

    beforeEach(function() {
      var filter1 = {
        modelName: 'soße',
        name: 'soße_id',
        type: 'list_model',
        operator: '=',
        values: ['knoblauch']
      };
      var filter2 = {
        name: 'created_at',
        type: 'date_past',
        operator: '<t-',
        textValue: '5'
      };
      query = new Query({
        id: 1,
        name: 'knoblauch soße',
        projectId: 2,
        displaySums: true,
        columns: [{ name: 'type' }, { name: 'status' }, { name: 'soße' }],
        groupBy: 'status',
        sortCriteria: 'type:desc',
        filters: [filter1, filter2]
      }, { rawFilters: true });
    });

    it('should encode query to params JSON', function() {
      var encodedJSON = UrlParamsHelper.encodeQueryJsonParams(query);
      var expectedJSON = "{\"c\":[\"type\",\"status\",\"soße\"],\"s\":true,\"p\":2,\"g\":\"status\",\"t\":\"type:desc\",\"f\":[{\"n\":\"soße_id\",\"o\":\"%3D\",\"t\":\"list_model\",\"v\":[\"knoblauch\"]},{\"n\":\"created_at\",\"o\":\"%3Ct-\",\"t\":\"date_past\",\"v\":\"5\"}],\"pa\":1,\"pp\":10}";
      expect(encodedJSON).to.eq(expectedJSON);
    });
  });

  describe('decodeQueryFromJsonParams', function() {
    var params;
    var queryId;

    beforeEach(function() {
      params = "{\"c\":[\"type\",\"status\",\"soße\"],\"s\":true,\"p\":2,\"g\":\"status\",\"t\":\"type:desc\",\"f\":[{\"n\":\"soße_id\",\"o\":\"%3D\",\"t\":\"list_model\",\"v\":[\"knoblauch\"]},{\"n\":\"created_at\",\"o\":\"%3Ct-\",\"t\":\"date_past\",\"v\":\"5\"}]}";
      queryId = 2;
    });

    it('should decode query params to object', function() {
      var decodedQueryParams = UrlParamsHelper.decodeQueryFromJsonParams(queryId, params);

      var expected = {
        id: queryId,
        projectId: 2,
        displaySums: true,
        columns: [{ name: 'type' }, { name: 'status' }, { name: 'soße' }],
        groupBy: 'status',
        sortCriteria: 'type:desc',
        filters: [{
          name: 'soße_id',
          type: 'list_model',
          operator: '=',
          values: ['knoblauch']
        },{
          name: 'created_at',
          type: 'date_past',
          operator: '<t-',
          values: ['5']
        }]
      };

      expect(angular.equals(decodedQueryParams, expected)).to.be.true;
    });
  });


  describe('buildQueryExportOptions', function() {
    var queryDummy = {
      exportFormats: [ { identifier: 'atom', format: 'atom' } ],
      getQueryString: function() { return '' }
    };
    var exportOptions;
    var queryExportSuffix = '\\/work_packages.atom\\?set_filter=1&';

    var shouldBehaveLikeExportForProjectWorkPackages = function(relativeUrl) {
      context('project query', function() {
        beforeEach(function() {
          var query = angular.copy(queryDummy);

          query.project_id = 1;

          exportOptions = UrlParamsHelper.buildQueryExportOptions(query);
        });

        it('should have project path', function() {
          var urlPattern = new RegExp(relativeUrl + '\\/projects\\/1' + queryExportSuffix);

          expect(exportOptions[0].url).to.match(urlPattern);
        });
      });
    };

    var shouldBehaveLikeExportForGlobalWorkPackages = function(relativeUrl) {
      context('global query', function() {
        beforeEach(function() {
          exportOptions = UrlParamsHelper.buildQueryExportOptions(queryDummy);
        });

        it('should have global path', function() {
          var urlPattern = new RegExp(relativeUrl + queryExportSuffix);

          expect(exportOptions[0].url).to.match(urlPattern);
        });
      });
    };

    context('no relative url', function() {
      shouldBehaveLikeExportForProjectWorkPackages('');

      shouldBehaveLikeExportForGlobalWorkPackages('');
    });

    context('relative url', function() {
      beforeEach(function() {
        PathHelper.staticBase = '/dev';
      });

      afterEach(function() {
        PathHelper.staticBase = '';
      });

      shouldBehaveLikeExportForProjectWorkPackages('\\/dev');

      shouldBehaveLikeExportForGlobalWorkPackages('\\/dev');
    });
  });
});
