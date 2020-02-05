//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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
// See docs/COPYRIGHT.rdoc for more details.
//++

/*jshint expr: true*/

import {UrlParamsHelperService} from 'core-components/wp-query/url-params-helper';

describe('UrlParamsHelper', function() {
  const paginationStub = {
    getPerPage: () => 20
  } as any;

  let UrlParamsHelper = new UrlParamsHelperService(paginationStub);
  let queryString;

  describe('buildQueryString', function() {
    const params = {
      ids: [1, 2, 3],
      str: '@#$%'
    };
    let queryString:string;

    beforeEach(function() {
      queryString = UrlParamsHelper.buildQueryString(params)!;
    });

    it('concatenates propertys with \'&\'', function() {
      expect(queryString.split('&').length).toEqual(4);
    });

    it('escapes special characters', function() {
      expect(queryString.indexOf('@') === -1).toBeTruthy();
    });
  });

  describe('encodeQueryJsonParams', function(){
    let query:any;
    let additional:any;

    beforeEach(function() {
      let filter1 = {
        id: 'soße',
        name: 'soße_id',
        type: 'list_model',
        operator: {
          id: '='
        },
        filter: {
          $href: '/api/filter/soße'
        },
        values: ['knoblauch']
      };
      let filter2 = {
        id: 'created_at',
        type: 'datetime_past',
        operator: {
          id: '<t-'
        },
        filter: {
          $href: '/api/filter/created_at'
        },
        values: ['5']
      };
      query = {
        id: 1,
        name: 'knoblauch soße',
        sums: true,
        timelineVisible: true,
        timelineZoomLevel: 'days',
        showHierarchies: true,
        highlightingMode: 'disabled',
        columns: [{ id: 'type' }, { id: 'status' }, { id: 'soße' }],
        groupBy: {
          id: 'status'
        },
        sortBy: [{
          id: 'type-desc'
        }],
        filters: [filter1, filter2]
      };

      additional = {
        page: 10,
        perPage: 100
      }
    });

    it('should encode query to params JSON', function() {
      let encodedJSON = UrlParamsHelper.encodeQueryJsonParams(query, additional);
      let expectedJSON = "{\"c\":[\"type\",\"status\",\"soße\"],\"s\":true,\"tv\":true,\"tzl\":\"days\",\"hl\":\"disabled\",\"hi\":true,\"g\":\"status\",\"t\":\"type:desc\",\"f\":[{\"n\":\"soße\",\"o\":\"=\",\"v\":[\"knoblauch\"]},{\"n\":\"created_at\",\"o\":\"<t-\",\"v\":[\"5\"]}],\"pa\":10,\"pp\":100}";

      expect(encodedJSON).toEqual(expectedJSON);
    });
  });

  describe('buildV3GetQueryFromJsonParams', function() {
    let params:string;

    beforeEach(function() {
      params = "{\"c\":[\"type\",\"status\",\"soße\"],\"s\":true,\"tv\":true,\"tzl\":\"days\",\"hl\":\"inline\",\"hi\":true,\"g\":\"status\",\"t\":\"type:desc,status:asc\",\"f\":[{\"n\":\"soße\",\"o\":\"=\",\"v\":[\"knoblauch\"]},{\"n\":\"created_at\",\"o\":\"<t-\",\"v\":[\"5\"]}],\"pa\":10,\"pp\":100}";
    });

    it('should decode query params to object', function() {
      let decodedQueryParams = UrlParamsHelper.buildV3GetQueryFromJsonParams(params);

      let expected = {
        'columns[]': ['type', 'status', 'soße'],
        showSums: true,
        timelineVisible: true,
        showHierarchies: true,
        timelineZoomLevel: 'days',
        highlightingMode: 'inline',
        groupBy: 'status',
        filters: JSON.stringify([
          {
            soße: {
              operator: '=',
              values: ['knoblauch']
            }
          },
          {
            created_at: {
              operator: '<t-',
              values: ['5']
            }
          }
        ]),
        sortBy: JSON.stringify([['type', 'desc'], ['status', 'asc']]),
        offset: 10,
        pageSize: 100
      };

      expect(_.isEqual(decodedQueryParams, expected)).toBeTruthy();
    });
  });

  describe('buildV3GetQueryFromQueryResource', function() {
    let query:any;
    let additional:any;

    it('decodes query params to object', function() {
      let filter1 = {
        id: 'soße',
        name: 'soße_id',
        type: 'list_model',
        operator: {
          id: '='
        },
        filter: {
          $href: '/api/filter/soße'
        },
        values: ['knoblauch']
      };
      let filter2 = {
        id: 'created_at',
        type: 'datetime_past',
        operator: {
          id: '<t-'
        },
        filter: {
          $href: '/api/filter/created_at'
        },
        values: ['5']
      };
      query = {
        id: 1,
        name: 'knoblauch soße',
        timelineZoomLevel: 0,
        timelineLabels: { left: 'foo', right: 'bar', farRight: 'asdf' },
        highlightingMode: 'inline',
        highlightedAttributes: [{href: 'a'}, {href: 'b'}],
        sums: true,
        columns: [{ id: 'type' }, { id: 'status' }, { id: 'soße' }],
        groupBy: {
          id: 'status'
        },
        sortBy: [
          {
            id: 'type-desc'
          },
          {
            id: 'status-asc'
          }
        ],
        filters: [filter1, filter2]
      };

      additional = {
        offset: 10,
        pageSize: 100
      };

      let v3Params = UrlParamsHelper.buildV3GetQueryFromQueryResource(query, additional);

      let expected = {
        'columns[]': ['type', 'status', 'soße'],
        showSums: true,
        groupBy: 'status',
        filters: JSON.stringify([
          {
            soße: {
              operator: '=',
              values: ['knoblauch']
            }
          },
          {
            created_at: {
              operator: '<t-',
              values: ['5']
            }
          }
        ]),
        sortBy: JSON.stringify([['type', 'desc'], ['status', 'asc']]),
        timelineVisible: false,
        showHierarchies: false,
        highlightingMode: 'inline',
        'highlightedAttributes[]': ['a', 'b'],
        offset: 10,
        pageSize: 100
      };

      expect(_.isEqual(v3Params, expected)).toBeTruthy();
    });

    it('decodes string object filters', function() {
      let filter1 = {
        id: 'customField1',
        operator: {
          id: '='
        },
        filter: {
          $href: '/api/filter/customField1'
        },
        values: [
          {
            _type: "StringObject",
            value: "val2val",
            $href: "/api/v3/string_objects/?value=val2val"
          },
          {
            _type: "StringObject",
            value: "7val7",
            $href: "/api/v3/string_objects/?value=7val7"
          }
        ]
      };
      query = {
        filters: [filter1],
        sortBy: [],
        columns: [],
        groupBy: '',
        timelineZoomLevel: 0,
        highlightingMode: 'inline',
        sums: false
      };

      additional = {}

      let v3Params = UrlParamsHelper.buildV3GetQueryFromQueryResource(query, additional);

      let expected = {
        'columns[]': [],
        filters: JSON.stringify([
          {
            customField1: {
              operator: '=',
              values: ['val2val', '7val7']
            }
          }
        ]),
        groupBy: '',
        showSums: false,
        timelineVisible: false,
        showHierarchies: false,
        highlightingMode: 'inline',

        sortBy: '[]'
      };

      expect(_.isEqual(v3Params, expected)).toBeTruthy();
    });
  });
});
