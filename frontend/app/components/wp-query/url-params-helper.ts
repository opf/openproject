//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

import {QuerySortByResource} from "../api/api-v3/hal-resources/query-sort-by-resource.service";
import {QueryResource} from "../api/api-v3/hal-resources/query-resource.service";
import {PathHelperService} from '../common/path-helper/path-helper.service';
import {HalLink} from 'core-components/api/api-v3/hal-link/hal-link.service';

export class UrlParamsHelperService {

  public constructor(public paginationService:any, public PathHelper:PathHelperService) {

  }

  // copied more or less from angular buildUrl
  public buildQueryString(params:any) {
    if (!params) {
      return undefined;
    }

    var parts:string[] = [];
    angular.forEach(params, function (value, key) {
      if (!value) return;
      if (!Array.isArray(value)) value = [value];

      angular.forEach(value, function (v) {
        if (v !== null && typeof v === 'object') {
          v = JSON.stringify(v);
        }
        parts.push(encodeURIComponent(key) + '=' +
          encodeURIComponent(v));
      });
    });

    return parts.join('&');
  }

  public encodeQueryJsonParams(query:QueryResource, additional:any) {
    var paramsData:any = {
      c: query.columns.map(function (column) {
        return column.id;
      })
    };
    if (!!query.sums) {
      paramsData.s = query.sums;
    }

    if (!!query.timelineVisible) {
      paramsData.tv = query.timelineVisible;
    }

    if (!_.isEmpty(query.timelineLabels)) {
      paramsData.tll = JSON.stringify(query.timelineLabels);
    }

    paramsData.tzl = query.timelineZoomLevel;
    paramsData.hi = !!query.showHierarchies;
    paramsData.g = _.get(query.groupBy, 'id', '');
    if (query.sortBy) {
      paramsData.t = query
        .sortBy
        .map(function (sort:QuerySortByResource) {
          return sort.id.replace('-', ':')
        })
        .join();
    }
    if (query.filters && query.filters.length) {
      paramsData.f = query
        .filters
        .map((filter:any) => {
          var id = filter.id;

          var operator = filter.operator.id;

          return {
            n: id,
            o: encodeURIComponent(operator),
            v: _.map(filter.values, (v) => this.queryFilterValueToParam(v))
          };
        });
    } else {
      paramsData.f = [];
    }

    paramsData.pa = additional.page;
    paramsData.pp = additional.perPage;

    return JSON.stringify(paramsData);
  }

  public buildV3GetQueryFromJsonParams(updateJson:any) {
    var queryData:any = {
      pageSize: this.paginationService.getPerPage()
    }

    if (!updateJson) {
      return queryData;
    }

    var properties = JSON.parse(updateJson);

    if (properties.c) {
      queryData["columns[]"] = properties.c.map((column:any) => column);
    }
    if (!!properties.s) {
      queryData.showSums = properties.s;
    }
    if (!!properties.tv) {
      queryData.timelineVisible = properties.tv;
    }
    if (!!properties.tll) {
      queryData.timelineLabels = properties.tll;
    }

    if (properties.tzl) {
      queryData.timelineZoomLevel = properties.tzl;
    }

    if (properties.hi === false || properties.hi === true) {
      queryData.showHierarchies = properties.hi;
    }

    queryData.groupBy = _.get(properties, 'g', '');

    // Filters
    if (properties.f) {
      var filters = properties.f.map(function (urlFilter:any) {
        var attributes = {
          operator: decodeURIComponent(urlFilter.o)
        }
        if (urlFilter.v) {
          // the array check is only there for backwards compatibility reasons.
          // Nowadays, it will always be an array;
          var vs = Array.isArray(urlFilter.v) ? urlFilter.v : [urlFilter.v];
          angular.extend(attributes, {values: vs});
        }
        const filterData:any = {};
        filterData[urlFilter.n] = attributes;

        return filterData;
      });

      queryData.filters = JSON.stringify(filters);
    }

    // Sortation
    if (properties.t) {
      queryData.sortBy = JSON.stringify(properties.t.split(',').map((sort:any) => sort.split(':')));
    }

    // Pagination
    if (properties.pa) {
      queryData.offset = properties.pa;
    }
    if (properties.pp) {
      queryData.pageSize = properties.pp;
    }

    return queryData;
  }

  public buildV3GetQueryFromQueryResource(query:QueryResource, additionalParams:any) {
    var queryData:any = {};

    queryData["columns[]"] = this.buildV3GetColumnsFromQueryResource(query);
    queryData.showSums = query.sums;
    queryData.timelineVisible = query.timelineVisible;
    queryData.timelineZoomLevel = query.timelineZoomLevel;
    queryData.showHierarchies = query.showHierarchies;
    queryData.groupBy = _.get(query.groupBy, 'id', '');

    // Filters
    queryData.filters = this.buildV3GetFiltersFromQueryResoure(query);

    // Sortation
    queryData.sortBy = this.buildV3GetSortByFromQuery(query);

    return angular.extend(queryData, additionalParams);
  }

  public queryFilterValueToParam(value:any) {
    if (typeof(value) === 'boolean') {
      return value ? 't' : 'f';
    }

    if (!value) {
      return '';
    } else if (value.id) {
      return value.id.toString();
    } else if (value.$href && value.$href.match(/^\/api\/v3\/string_objects/i)) {
      return value.$href.match(/value=([^&]+)/)[1].toString();
    } else if (value.$href) {
      return value.$href.split('/').pop().toString();
    } else {
      return value.toString();
    }
  }

  private buildV3GetColumnsFromQueryResource(query:QueryResource) {
    if (query.columns) {
      return query.columns.map((column: any) => column.id);
    } else if (query._links.columns) {
      return query._links.columns.map((column:HalLink) => {
        let id = column.href!;

        return this.idFromHref(id);
      });
    }
  }

  private buildV3GetFiltersFromQueryResoure(query:QueryResource) {
    let filters = query.filters.map((filter:any) => {
      let id = this.buildV3GetFilterIdFromFilter(filter);
      let operator = this.buildV3GetOperatorIdFromFilter(filter);
      let values = this.buildV3GetValuesFromFilter(filter);

      const filterHash:any = {};
      filterHash[id] = {operator: operator, values: values};

      return filterHash;
    });

    return JSON.stringify(filters);
  }

  private buildV3GetFilterIdFromFilter(filter:any) {
    let href = filter.filter ? filter.filter.$href : filter._links.filter.href;

    return this.idFromHref(href)
  }

  private buildV3GetOperatorIdFromFilter(filter:any) {
    if (filter.operator) {
      return filter.operator.id;
    } else {
      let href = filter._links.operator.href;

      return this.idFromHref(href);
    }
  }

  private buildV3GetValuesFromFilter(filter:any) {
    let values = filter.values ? filter.values : filter._links.values;

    return _.map(values, (v) => this.queryFilterValueToParam(v));
  }

  private buildV3GetSortByFromQuery(query:QueryResource) {
    let sortBys = query.sortBy ? query.sortBy : query._links.sortBy;
    let sortByIds = sortBys.map((sort:QuerySortByResource) => {
      if (sort.id) {
        return sort.id;
      } else {
        let href = sort.href!;

        let id = this.idFromHref(href);

        return id;
      }
    });

    return JSON.stringify(sortByIds.map((id:string) => id.split('-')));
  }

  private idFromHref(href:string) {
    return href.substring(href.lastIndexOf('/') + 1, href.length);
  }
}

angular.module('openproject.helpers')
  .service('UrlParamsHelper', UrlParamsHelperService);
