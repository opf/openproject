//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { merge } from 'lodash-es';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { QuerySortByResource } from 'core-app/features/hal/resources/query-sort-by-resource';
import { HalLink } from 'core-app/features/hal/hal-link/hal-link';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import isPersistedResource from 'core-app/features/hal/helpers/is-persisted-resource';
import { Injectable, inject } from '@angular/core';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { ApiV3Filter, ApiV3FilterBuilder, FilterOperator } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { PaginationService } from 'core-app/shared/components/table-pagination/pagination-service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { QueryFilterResource } from 'core-app/features/hal/resources/query-filter-resource';

export interface QueryPropsFilter {
  n:string;
  o:string
  v:unknown;
}

export interface QueryProps {
  // Columns
  c:string[];
  // Sums enabled?
  s?:boolean;
  // Sort by criteria
  t?:string;
  // Group by criteria
  g:string|null;
  // Filters
  f:QueryPropsFilter[];
  // Hierarchies
  hi:boolean;
  // Highlighting mode
  hl?:string;
  // Highlighted attributes
  hla?:string[];
  // Display representation
  dr?:string;
  // Include subprojects
  is?:boolean;
  // Pagination
  pa?:string|number;
  pp?:string|number;

  // Timeline options
  tv?:boolean;
  tzl?:string;
  tll?:string;

  // Timestamps options
  ts?:string;
}

export interface QueryRequestParams {
  page?:string|number;
  pageSize:string|number;
  offset:string|number;
  'columns[]':string[];
  showSums:boolean;
  timelineVisible:boolean;
  timelineLabels:string;
  timelineZoomLevel:string;
  displayRepresentation:string;
  includeSubprojects:boolean;
  highlightingMode:string;
  'highlightedAttributes[]':string[];
  showHierarchies:boolean;
  groupBy:string|null;
  filters:string;
  sortBy:string;
  query_id:string|null;
  timestamps:string;
  valid_subset?:boolean;
}

type QueryFilterValue = HalResource|string|boolean;

interface QueryValueLink {
  href:string;
}

@Injectable({ providedIn: 'root' })
export class UrlParamsHelperService {
  paginationService = inject(PaginationService);


  // copied more or less from angular buildUrl
  public buildQueryString(params:any) {
    if (!params) {
      return undefined;
    }

    const parts:string[] = [];
    Object.entries(params as Record<string, unknown>).forEach(([key, value]) => {
      if (value === undefined || value === null) {
        return;
      }
      const values:unknown[] = Array.isArray(value) ? value as unknown[] : [value];

      values.forEach((v) => {
        const encoded = (v !== null && typeof v === 'object') ? JSON.stringify(v) : v as string;
        parts.push(`${encodeURIComponent(key)}=${
          encodeURIComponent(encoded)}`);
      });
    });

    return parts.join('&');
  }

  public encodeQueryJsonParams(
    query:QueryResource,
    extender?:Partial<QueryProps>|((paramsData:QueryProps) => QueryProps),
  ):string {
    const paramsData:QueryProps = {
      c: query.columns.map((column) => column.id),
      hi: !!query.showHierarchies,
      g: _.get(query.groupBy, 'id', ''),
      dr: query.displayRepresentation,
      is: query.includeSubprojects,
      ...this.encodeSums(query),
      ...this.encodeTimelineVisible(query),
      ...this.encodeHighlightingMode(query),
      ...this.encodeHighlightedAttributes(query),
      ...this.encodeSortBy(query),
      ...this.encodeFilters(query.filters),
      ...this.encodeTimestamps(query),
    };

    if (typeof extender === 'function') {
      return JSON.stringify(extender(paramsData));
    }

    if (typeof extender === 'object') {
      return JSON.stringify(merge(paramsData, extender));
    }

    return JSON.stringify(paramsData);
  }

  private encodeSums(query:QueryResource):Partial<QueryProps> {
    if (query.sums) {
      return { s: query.sums };
    }

    return {};
  }

  private encodeHighlightingMode(query:QueryResource):Partial<QueryProps> {
    if (query.highlightingMode && (isPersistedResource(query) || query.highlightingMode !== 'inline')) {
      return { hl: query.highlightingMode };
    }

    return {};
  }

  private encodeHighlightedAttributes(query:QueryResource):Partial<QueryProps> {
    if (query.highlightingMode === 'inline') {
      if (Array.isArray(query.highlightedAttributes) && query.highlightedAttributes.length > 0) {
        return { hla: query.highlightedAttributes.map((el) => idFromLink(el.href)) };
      }
    }

    return {};
  }

  private encodeSortBy(query:QueryResource):Partial<QueryProps> {
    if (query.sortBy) {
      return {
        t: query
          .sortBy
          .map((sort:QuerySortByResource) => sort.id!.replace('-', ':'))
          .join(),
      };
    }

    return {};
  }

  private encodeTimestamps(query:QueryResource):Partial<QueryProps> {
    if (query.timestamps) {
      return { ts: query.timestamps.join(',') };
    }

    return {};
  }

  public encodeFilters(filters:QueryFilterInstanceResource[]):Pick<QueryProps, 'f'> {
    if (filters && filters.length > 0) {
      const filterProps:QueryPropsFilter[] = filters.map((filter) => ({
        n: filter.id,
        o: filter.operator.id,
        v: filter.values.map((value:HalResource|string) => this.queryFilterValueToParam(value)),
      }));

      return { f: filterProps };
    }

    return { f: [] };
  }

  private encodeTimelineVisible(query:QueryResource):Partial<QueryProps> {
    const paramsData:Partial<QueryProps> = {};

    if (query.timelineVisible) {
      paramsData.tv = query.timelineVisible;

      if (Object.keys(query.timelineLabels ?? {}).length > 0) {
        paramsData.tll = JSON.stringify(query.timelineLabels);
      }

      paramsData.tzl = query.timelineZoomLevel;
    } else {
      paramsData.tv = false;
    }

    return paramsData;
  }

  public buildV3GetQueryFromJsonParams(updateJson:string|null) {
    const queryData:Partial<QueryRequestParams> = {
      pageSize: this.paginationService.getPerPage(),
    };

    if (!updateJson) {
      return queryData;
    }

    const properties = JSON.parse(updateJson) as QueryProps;

    if (properties.c) {
      queryData['columns[]'] = properties.c.map((column:any) => column);
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

    if (properties.is !== undefined) {
      queryData.includeSubprojects = properties.is;
    }

    if (properties.hl) {
      queryData.highlightingMode = properties.hl;
    }

    if (properties.hla) {
      queryData['highlightedAttributes[]'] = properties.hla.map((column:any) => column);
    }

    if (properties.hi !== undefined) {
      queryData.showHierarchies = properties.hi;
    }

    queryData.groupBy = _.get(properties, 'g', '');

    // Filters
    if (properties.f) {
      const filters = properties.f.map((urlFilter:QueryPropsFilter) => {
        const attributes:{ operator:string, values?:unknown[] } = {
          operator: decodeURIComponent(urlFilter.o),
        };
        if (urlFilter.v) {
          // the array check is only there for backwards compatibility reasons.
          // Nowadays, it will always be an array;
          const vs = Array.isArray(urlFilter.v) ? urlFilter.v : [urlFilter.v];
          attributes.values = vs;
        }
        const filterData:Record<string, typeof attributes> = {};
        filterData[urlFilter.n] = attributes;

        return filterData;
      });

      queryData.filters = JSON.stringify(filters);
    }

    // Sortation
    if (properties.t) {
      queryData.sortBy = JSON.stringify(properties.t.split(',').map((sort:any) => sort.split(':')));
    }

    if (properties.ts) {
      queryData.timestamps = properties.ts;
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

  public buildV3GetQueryFromQueryResource(
    query:QueryResource,
    additionalParams:object = {},
    contextual:Record<string, string> = {},
  ):Partial<QueryRequestParams> {
    const queryData:Partial<QueryRequestParams> = {};

    queryData['columns[]'] = this.buildV3GetColumnsFromQueryResource(query);
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
      queryData['highlightedAttributes[]'] = query.highlightedAttributes.map((el) => el.href!);
    }

    if (query.displayRepresentation) {
      queryData.displayRepresentation = query.displayRepresentation;
    }

    queryData.includeSubprojects = !!query.includeSubprojects;
    queryData.showHierarchies = !!query.showHierarchies;
    queryData.groupBy = _.get(query.groupBy, 'id', '');

    // Filters
    queryData.filters = this.buildV3GetFiltersAsJson(query.filters, contextual);

    // Sortation
    queryData.sortBy = this.buildV3GetSortByFromQuery(query);
    queryData.timestamps = query.timestamps.join(',');

    return Object.assign(additionalParams, queryData);
  }

  public queryFilterValueToParam(value:HalResource|string|boolean):string {
    if (typeof (value) === 'boolean') {
      return value ? 't' : 'f';
    }

    if (!value) {
      return '';
    }

    const halValue = value as HalResource;
    if (halValue.id) {
      return halValue.id.toString();
    }
    if (halValue.href) {
      return halValue.href.split('/').pop()!;
    }

    return value.toString();
  }

  private buildV3GetColumnsFromQueryResource(query:QueryResource):string[] {
    if (query.columns) {
      return query.columns.map((column:any) => column.id || idFromLink(column.href)) as string[];
    }
    if (query._links.columns) {
      return query._links.columns.map((column:HalLink) => idFromLink(column.href)) as string[];
    }

    return [];
  }

  public buildV3GetFilters(filters:QueryFilterInstanceResource[], replacements:Record<string, string> = {}):ApiV3Filter[] {
    const newFilters = filters.map((filter:QueryFilterInstanceResource) => {
      const id = this.buildV3GetFilterIdFromFilter(filter);
      const operator = this.buildV3GetOperatorIdFromFilter(filter);
      const values = this.buildV3GetValuesFromFilter(filter).map((value:string) => {
        Object.entries(replacements).forEach(([key, val]:[string, string]) => {
          value = value.replace(`{${key}}`, val);
        });

        return value;
      });

      const filterHash:ApiV3Filter = {};
      filterHash[id] = { operator: operator as FilterOperator, values };

      return filterHash;
    });

    return newFilters;
  }

  public filterBuilderFrom(filters:QueryFilterInstanceResource[]) {
    const builder:ApiV3FilterBuilder = new ApiV3FilterBuilder();

    filters.forEach((filter:QueryFilterInstanceResource) => {
      const id = this.buildV3GetFilterIdFromFilter(filter);
      const operator = this.buildV3GetOperatorIdFromFilter(filter) as FilterOperator;
      const values = this.buildV3GetValuesFromFilter(filter);

      builder.add(id, operator, values);
    });

    return builder;
  }

  public buildV3GetFiltersAsJson(filter:QueryFilterInstanceResource[], contextual:Record<string, string> = {}) {
    return JSON.stringify(this.buildV3GetFilters(filter, contextual));
  }

  public buildV3GetFilterIdFromFilter(filter:QueryFilterInstanceResource) {
    const href = filter.filter ? filter.filter.href : filter._links.filter.href;

    return idFromLink(href as string);
  }

  public buildV3GetValuesFromFilter(filter:QueryFilterInstanceResource|QueryFilterResource):string[] {
    if (filter.values) {
      return (filter.values as QueryFilterValue[]).map((v) => this.queryFilterValueToParam(v));
    }
    return (filter._links as { values:QueryValueLink[] }).values.map((v) => idFromLink(v.href));
  }

  private buildV3GetOperatorIdFromFilter(filter:QueryFilterInstanceResource) {
    if (filter.operator) {
      return filter.operator.id || idFromLink(filter.operator.href);
    }
    const { href } = filter._links.operator;

    return idFromLink(href as string);
  }

  private buildV3GetSortByFromQuery(query:QueryResource) {
    const sortBys = query.sortBy ? query.sortBy : query._links.sortBy;
    const sortByIds = sortBys.map((sort:QuerySortByResource) => {
      if (sort.id) {
        return sort.id;
      }
      return idFromLink(sort.href);
    });

    return JSON.stringify(sortByIds.map((id:string) => id.split('-')));
  }
}
