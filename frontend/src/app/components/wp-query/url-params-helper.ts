//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { QueryResource } from 'core-app/modules/hal/resources/query-resource';
import { QuerySortByResource } from 'core-app/modules/hal/resources/query-sort-by-resource';
import { HalLink } from 'core-app/modules/hal/hal-link/hal-link';
import { Injectable } from '@angular/core';
import { PaginationService } from 'core-components/table-pagination/pagination-service';
import { QueryFilterInstanceResource } from 'core-app/modules/hal/resources/query-filter-instance-resource';
import { ApiV3Filter, FilterOperator } from "core-components/api/api-v3/api-v3-filter-builder";

@Injectable({ providedIn: 'root' })
export class UrlParamsHelperService {

  public constructor(public paginationService:PaginationService) {
  }

  // copied more or less from angular buildUrl
  public buildQueryString(params:any) {
    if (!params) {
      return undefined;
    }

    const parts:string[] = [];
    _.each(params, (value, key) => {
      if (!value) {
        return;
      }
      if (!Array.isArray(value)) {
        value = [value];
      }

      _.each(value, (v) => {
        if (v !== null && typeof v === 'object') {
          v = JSON.stringify(v);
        }
        parts.push(encodeURIComponent(key) + '=' +
          encodeURIComponent(v));
      });
    });

    return parts.join('&');
  }

  public encodeQueryJsonParams(query:QueryResource, additional:any = {}) {
    let paramsData:any = {};

    paramsData = this.encodeColumns(paramsData, query);
    paramsData = this.encodeSums(paramsData, query);
    paramsData = this.encodeTimelineVisible(paramsData, query);
    paramsData = this.encodeHighlightingMode(paramsData, query);
    paramsData = this.encodeHighlightedAttributes(paramsData, query);
    paramsData.hi = !!query.showHierarchies;
    paramsData.g = _.get(query.groupBy, 'id', '');
    paramsData = this.encodeSortBy(paramsData, query);
    paramsData = this.encodeFilters(paramsData, query.filters);
    paramsData.pa = additional.page;
    paramsData.pp = additional.perPage;
    paramsData.dr = query.displayRepresentation;

    return JSON.stringify(paramsData);
  }

  private encodeColumns(paramsData:any, query:QueryResource) {
    paramsData.c = query.columns.map(function (column) {
      return column.id!;
    });

    return paramsData;
  }

  private encodeSums(paramsData:any, query:QueryResource) {
    if (query.sums) {
      paramsData.s = query.sums;
    }
    return paramsData;
  }

  private encodeHighlightingMode(paramsData:any, query:QueryResource) {
    if (query.highlightingMode && (query.persisted || query.highlightingMode !== 'inline')) {
      paramsData.hl = query.highlightingMode;
    }
    return paramsData;
  }

  private encodeHighlightedAttributes(paramsData:any, query:QueryResource) {
    if (query.highlightingMode === 'inline') {
      if (Array.isArray(query.highlightedAttributes) && query.highlightedAttributes.length > 0) {
        paramsData.hla = query.highlightedAttributes.map(el => el.id);
      }
    }
    return paramsData;
  }

  private encodeSortBy(paramsData:any, query:QueryResource) {
    if (query.sortBy) {
      paramsData.t = query
        .sortBy
        .map(function (sort:QuerySortByResource) {
          return sort.id!.replace('-', ':');
        })
        .join();
    }
    return paramsData;
  }

  public encodeFilters(paramsData:any, filters:QueryFilterInstanceResource[]) {
    if (filters && filters.length > 0) {
      paramsData.f = filters
        .map((filter:any) => {
          var id = filter.id;

          var operator = filter.operator.id;

          return {
            n: id,
            o: operator,
            v: _.map(filter.values, (v) => this.queryFilterValueToParam(v))
          };
        });
    } else {
      paramsData.f = [];
    }
    return paramsData;
  }

  private encodeTimelineVisible(paramsData:any, query:QueryResource) {
    if (query.timelineVisible) {
      paramsData.tv = query.timelineVisible;

      if (!_.isEmpty(query.timelineLabels)) {
        paramsData.tll = JSON.stringify(query.timelineLabels);
      }

      paramsData.tzl = query.timelineZoomLevel;
    } else {
      paramsData.tv = false;
    }
    return paramsData;
  }


  public buildV3GetQueryFromJsonParams(updateJson:string|null) {
    var queryData:any = {
      pageSize: this.paginationService.getPerPage()
    };

    if (!updateJson) {
      return queryData;
    }

    var properties = JSON.parse(updateJson);

    if (properties.c) {
      queryData["columns[]"] = properties.c.map((column:any) => column);
    }
    if (properties.s) {
      queryData.showSums = properties.s;
    }

    queryData.timelineVisible = properties.tv;

    if (properties.tv) {
      if (properties.tll) {
        queryData.timelineLabels = properties.tll;
      }

      if (properties.tzl) {
        queryData.timelineZoomLevel = properties.tzl;
      }
    }

    if (properties.dr) {
      queryData.displayRepresentation = properties.dr;
    }

    if (properties.hl) {
      queryData.highlightingMode = properties.hl;
    }

    if (properties.hla) {
      queryData["highlightedAttributes[]"] = properties.hla.map((column:any) => column);
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
        };
        if (urlFilter.v) {
          // the array check is only there for backwards compatibility reasons.
          // Nowadays, it will always be an array;
          var vs = Array.isArray(urlFilter.v) ? urlFilter.v : [urlFilter.v];
          _.extend(attributes, { values: vs });
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

  public buildV3GetQueryFromQueryResource(query:QueryResource, additionalParams:any = {}, contextual:any = {}) {
    var queryData:any = {};

    queryData["columns[]"] = this.buildV3GetColumnsFromQueryResource(query);
    queryData.showSums = query.sums;
    queryData.timelineVisible = !!query.timelineVisible;

    if (query.timelineVisible) {
      queryData.timelineZoomLevel = query.timelineZoomLevel;
      queryData.timelineLabels = JSON.stringify(query.timelineLabels);
    }

    if (query.highlightingMode) {
      queryData.highlightingMode = query.highlightingMode;
    }

    if (query.highlightedAttributes && query.highlightingMode === 'inline') {
      queryData['highlightedAttributes[]'] = query.highlightedAttributes.map(el => el.href);
    }

    if (query.displayRepresentation) {
      queryData.displayRepresentation = query.displayRepresentation;
    }

    queryData.showHierarchies = !!query.showHierarchies;
    queryData.groupBy = _.get(query.groupBy, 'id', '');

    // Filters
    queryData.filters = this.buildV3GetFiltersAsJson(query.filters, contextual);

    // Sortation
    queryData.sortBy = this.buildV3GetSortByFromQuery(query);

    return _.extend(additionalParams, queryData);
  }

  public queryFilterValueToParam(value:any) {
    if (typeof(value) === 'boolean') {
      return value ? 't' : 'f';
    }

    if (!value) {
      return '';
    } else if (value.id) {
      return value.id.toString();
    } else if (value.$href) {
      return value.$href.split('/').pop().toString();
    } else {
      return value.toString();
    }
  }

  private buildV3GetColumnsFromQueryResource(query:QueryResource) {
    if (query.columns) {
      return query.columns.map((column:any) => column.id || column.idFromLink);
    } else if (query._links.columns) {
      return query._links.columns.map((column:HalLink) => {
        const id = column.href!;

        return this.idFromHref(id);
      });
    }
  }

  public buildV3GetFilters(filters:QueryFilterInstanceResource[], replacements = {}):ApiV3Filter[] {
    const newFilters = filters.map((filter:QueryFilterInstanceResource) => {
      const id = this.buildV3GetFilterIdFromFilter(filter);
      const operator = this.buildV3GetOperatorIdFromFilter(filter);
      const values = this.buildV3GetValuesFromFilter(filter).map(value => {
        _.each(replacements, (val:string, key:string) => {
          value = value.replace(`{${key}}`, val);
        });

        return value;
      });

      const filterHash:ApiV3Filter = {};
      filterHash[id] = { operator: operator as FilterOperator, values: values };

      return filterHash;
    });

    return newFilters;
  }

  public buildV3GetFiltersAsJson(filter:QueryFilterInstanceResource[], contextual = {}) {
    return JSON.stringify(this.buildV3GetFilters(filter, contextual));
  }

  public buildV3GetFilterIdFromFilter(filter:QueryFilterInstanceResource) {
    const href = filter.filter ? filter.filter.$href : filter._links.filter.href;

    return this.idFromHref(href);
  }

  private buildV3GetOperatorIdFromFilter(filter:QueryFilterInstanceResource) {
    if (filter.operator) {
      return filter.operator.id || filter.operator.idFromLink;
    } else {
      const href = filter._links.operator.href;

      return this.idFromHref(href);
    }
  }

  private buildV3GetValuesFromFilter(filter:QueryFilterInstanceResource) {
    if (filter.values) {
      return _.map(filter.values, (v:any) => this.queryFilterValueToParam(v));
    } else {
      return _.map(filter._links.values, (v:any) => this.idFromHref(v.href));
    }

  }

  private buildV3GetSortByFromQuery(query:QueryResource) {
    const sortBys = query.sortBy ? query.sortBy : query._links.sortBy;
    const sortByIds = sortBys.map((sort:QuerySortByResource) => {
      if (sort.id) {
        return sort.id;
      } else {
        const href = sort.href!;

        const id = this.idFromHref(href);

        return id;
      }
    });

    return JSON.stringify(sortByIds.map((id:string) => id.split('-')));
  }

  private idFromHref(href:string) {
    const id = href.substring(href.lastIndexOf('/') + 1, href.length);

    return decodeURIComponent(id);
  }
}
