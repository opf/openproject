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

import { CollectionResource } from "core-app/modules/hal/resources/collection-resource";
import { ApiV3FilterBuilder, FilterOperator } from "core-components/api/api-v3/api-v3-filter-builder";
import { Observable } from "rxjs";

export interface Apiv3ListParameters {
  filters?:[string, FilterOperator, string[]][];
  sortBy?:[string, string][];
  pageSize?:number;
}

export interface Apiv3ListResourceInterface<T> {
  list(params:Apiv3ListParameters):Observable<CollectionResource<T>>;
}

export function listParamsString(params?:Apiv3ListParameters):string {
  const queryProps = [];

  if (params && params.sortBy) {
    queryProps.push(`sortBy=${JSON.stringify(params.sortBy)}`);
  }

  // 0 should not be treated as false
  if (params && params.pageSize !== undefined) {
    queryProps.push(`pageSize=${params.pageSize}`);
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
