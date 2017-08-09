// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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

import {QueryResource} from '../api/api-v3/hal-resources/query-resource.service';
import {QueryFormResource} from '../api/api-v3/hal-resources/query-form-resource.service';
import {QuerySortByResource} from '../api/api-v3/hal-resources/query-sort-by-resource.service';
import {QueryGroupByResource} from '../api/api-v3/hal-resources/query-group-by-resource.service';
import {SchemaResource} from '../api/api-v3/hal-resources/schema-resource.service';
import {QueryFilterResource} from '../api/api-v3/hal-resources/query-filter-resource.service';
import {QueryFilterInstanceResource} from '../api/api-v3/hal-resources/query-filter-instance-resource.service';
import {QueryFilterInstanceSchemaResource} from '../api/api-v3/hal-resources/query-filter-instance-schema-resource.service';
import {QueryColumn} from '../wp-query/query-column';

export class WorkPackagesListInvalidQueryService {
  constructor(protected QueryResource:QueryResource,
              protected QueryFilterInstanceResource:QueryFilterInstanceResource) {}

  public restoreQuery(query:QueryResource, form:QueryFormResource) {
    let payload = new (this.QueryResource as any)(form.payload);

    this.restoreFilters(query, payload, form.schema);
    this.restoreColumns(query, payload, form.schema);
    this.restoreSortBy(query, payload, form.schema);
    this.restoreGroupBy(query, payload, form.schema);
    this.restoreOtherProperties(query, payload);
  }

  private restoreFilters(query:QueryResource, payload:QueryResource, querySchema:SchemaResource) {
    let filters = _.map((payload.filters as QueryFilterInstanceResource[]), filter => {
      let filterInstanceSchema = _.find(querySchema.filtersSchemas.elements, (schema:QueryFilterInstanceSchemaResource) => {
        return (schema.filter.allowedValues as QueryFilterResource[])[0].$href === filter.filter.$href;
      })

      if (!filterInstanceSchema) {
        return null;
      }

      let recreatedFilter = this.QueryFilterInstanceResource.fromSchema(filterInstanceSchema);

      let operator = _.find(filterInstanceSchema.operator.allowedValues, operator => {
        return operator.$href === filter.operator.$href;
      });

      if (operator) {
        recreatedFilter.operator = operator;
      }

      recreatedFilter.values.length = 0
      _.each(filter.values, value => recreatedFilter.values.push(value));

      return recreatedFilter;
    });

    filters = _.compact(filters);

    // clear filters while keeping reference
    query.filters.length = 0;
    _.each(filters, filter => query.filters.push(filter));
  }

  private restoreColumns(query:QueryResource, stubQuery:QueryResource, schema:SchemaResource) {
    let columns = _.map(stubQuery.columns, column => {
      return _.find((schema.columns.allowedValues as QueryColumn[]), candidate => {
        return candidate.$href === column.$href;
      });
    });

    columns = _.compact(columns);

    query.columns.length = 0;
    _.each(columns, column => query.columns.push(column!));
  }

  private restoreSortBy(query:QueryResource, stubQuery:QueryResource, schema:SchemaResource) {
    let sortBys = _.map((stubQuery.sortBy as QuerySortByResource[]), sortBy => {
      return _.find((schema.sortBy.allowedValues as QuerySortByResource[]), candidate => {
        return candidate.$href === sortBy.$href;
      })!;
    });

    sortBys = _.compact(sortBys);

    query.sortBy.length = 0;
    _.each(sortBys, sortBy => query.sortBy.push(sortBy));
  }

  private restoreGroupBy(query:QueryResource, stubQuery:QueryResource, schema:SchemaResource) {
    let groupBy = _.find((schema.groupBy.allowedValues as QueryGroupByResource[]), candidate => {
      return stubQuery.groupBy && stubQuery.groupBy.$href === candidate.$href;
    });

    query.groupBy = groupBy;
  }

  private restoreOtherProperties(query:QueryResource, stubQuery:QueryResource) {
    _.without(Object.keys(stubQuery.$source), '_links', 'filters').forEach((property:any) => {
      query[property] = stubQuery[property];
    });

    _.without(Object.keys(stubQuery.$source._links), 'columns', 'groupBy', 'sortBy').forEach((property:any) => {
      query[property] = stubQuery[property];
    });
  }
}

angular
  .module('openproject.workPackages.services')
  .service('wpListInvalidQueryService', WorkPackagesListInvalidQueryService);
