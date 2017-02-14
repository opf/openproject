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

import {
  QuerySortByResource,
  QUERY_SORT_BY_ASC,
  QUERY_SORT_BY_DESC
} from '../api/api-v3/hal-resources/query-sort-by-resource.service';
import {
  QueryResource,
  QueryColumn
} from '../api/api-v3/hal-resources/query-resource.service';
import {QuerySchemaResourceInterface} from '../api/api-v3/hal-resources/query-schema-resource.service';

export class WorkPackageTableSortBy {
  public available: QuerySortByResource[] = [];
  public current:QuerySortByResource[] = [];

  constructor(query:QueryResource, schema:QuerySchemaResourceInterface) {
    this.current = angular.copy(query.sortBy);
    this.available = angular.copy(schema.sortBy.allowedValues as QuerySortByResource[]);
  }

  public addCurrent(sortBy:QuerySortByResource) {
    this.current.unshift(sortBy);

    this.current = _.uniqBy(this.current,
                            sortBy => sortBy.column.$href)
                          .slice(0, 3);
  }

  public setCurrent(sortBys:QuerySortByResource[]) {
    this.current = [];

    _.reverse(sortBys);

    _.each(sortBys, sortBy => this.addCurrent(sortBy));
  }

  public addCurrentAsc(column:QueryColumn) {
    let available = this.findAvailableDirection(column, QUERY_SORT_BY_ASC);

    if (available) {
      this.addCurrent(available);
    }
  }

  public addCurrentDesc(column:QueryColumn) {
    let available = this.findAvailableDirection(column, QUERY_SORT_BY_DESC);

    if (available) {
      this.addCurrent(available);
    }
  }

  public isSortable(column:QueryColumn):boolean {
    return !!this.findAnyAvailable(column);
  }

  public findAnyAvailable(column:QueryColumn):QuerySortByResource|null {
    return _.find(this.available,
                  (candidate) => candidate.column.$href === column.$href) || null;
  }

  public findAvailableDirection(column:QueryColumn, direction:string):QuerySortByResource|null {
    return _.find(this.available,
                  (candidate) => (candidate.column.$href === column.$href &&
                                  candidate.direction.$href === direction)) || null;
  }
}
