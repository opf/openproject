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

import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { Observable } from 'rxjs';
import { ApiV3FilterBuilder, FilterOperator } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';

export type ApiV3ListFilter = [string, FilterOperator, boolean|string[]];

export interface ApiV3PaginationParameters {
  pageSize:number;
  offset:number;
}

export interface ApiV3ListParameters extends Partial<ApiV3PaginationParameters> {
  filters?:ApiV3ListFilter[];
  sortBy?:[string, string][];
  groupBy?:string;
  select?:string[];
}

export interface ApiV3ListResourceInterface<T> {
  list(params:ApiV3ListParameters):Observable<CollectionResource<T>>;
}

export function listParamsString(params?:ApiV3ListParameters):string {
  const queryProps = [];

  if (params && params.sortBy) {
    queryProps.push(`sortBy=${JSON.stringify(params.sortBy)}`);
  }

  if (params && params.groupBy) {
    queryProps.push(`groupBy=${params.groupBy}`);
  }

  // 0 should not be treated as false
  if (params && params.pageSize !== undefined) {
    queryProps.push(`pageSize=${params.pageSize}`);
  }

  // 0 should not be treated as false
  if (params && params.offset !== undefined) {
    queryProps.push(`offset=${params.offset}`);
  }

  if (params && params.select !== undefined) {
    queryProps.push(`select=${params.select.join(',')}`);
  }

  if (params && params.filters) {
    const filters = new ApiV3FilterBuilder();

    params.filters.forEach((filterParam) => {
      filters.add(...filterParam);
    });

    queryProps.push(filters.toParams());
  }

  let queryPropsString = '';

  if (queryProps.length) {
    queryPropsString = `?${queryProps.join('&')}`;
  }

  return queryPropsString;
}
