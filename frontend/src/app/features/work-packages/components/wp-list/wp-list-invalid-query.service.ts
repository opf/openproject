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

import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { Injectable, inject } from '@angular/core';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { QueryFilterInstanceSchemaResource } from 'core-app/features/hal/resources/query-filter-instance-schema-resource';
import { QueryFormResource } from 'core-app/features/hal/resources/query-form-resource';
import { QueryFilterResource } from 'core-app/features/hal/resources/query-filter-resource';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { QuerySortByResource } from 'core-app/features/hal/resources/query-sort-by-resource';
import { QueryGroupByResource } from 'core-app/features/hal/resources/query-group-by-resource';
import { QueryColumn } from '../wp-query/query-column';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { SchemaAttributeObject } from 'core-app/features/hal/resources/schema-attribute-object';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';

interface QueryFormSchemaProperties {
  columns:SchemaAttributeObject<QueryColumn>;
  sortBy:SchemaAttributeObject<QuerySortByResource>;
  groupBy:SchemaAttributeObject<QueryGroupByResource>;
  filtersSchemas:{ elements:QueryFilterInstanceSchemaResource[] };
}

type QueryFormSchema = SchemaResource & QueryFormSchemaProperties;

@Injectable()
export class WorkPackagesListInvalidQueryService {
  protected halResourceService = inject(HalResourceService);

  public restoreQuery(query:QueryResource, form:QueryFormResource) {
    const payload = form.payload as QueryResource;
    const schema = form.schema as QueryFormSchema;
    // The form's filter schemas are embedded under the schema, not at the
    // form's top level (`form.filtersSchemas` returns undefined). The
    // `QueryFormResource#filtersSchemas` getter is misleading — see
    // `apiv3-query-form.ts`, which also reads via `form.$embedded.schema...`.
    this.restoreFilters(query, payload, schema.filtersSchemas.elements);
    this.restoreColumns(query, payload, schema);
    this.restoreSortBy(query, payload, schema);
    this.restoreGroupBy(query, payload, schema);
    this.restoreOtherProperties(query, payload);
  }

  private restoreFilters(query:QueryResource, payload:QueryResource, filtersSchemas:QueryFilterInstanceSchemaResource[]) {
    const filters = payload.filters.map((filter) => {
      const filterInstanceSchema = filtersSchemas.find(
        (schema) => (schema.filter.allowedValues as QueryFilterResource[])[0].href === filter.filter.href,
      );

      if (!filterInstanceSchema) {
        return null;
      }

      const recreatedFilter = filterInstanceSchema.getFilter();

      const operator = (filterInstanceSchema.operator.allowedValues as HalResource[]).find(
        (op) => op.href === filter.operator.href,
      );

      if (operator) {
        recreatedFilter.operator = operator as typeof recreatedFilter.operator;
      }

      recreatedFilter.values = filter.values.slice();

      return recreatedFilter;
    }).filter((f):f is QueryFilterInstanceResource => f != null);

    // clear filters while keeping reference
    query.filters.length = 0;
    filters.forEach((filter) => query.filters.push(filter));
  }

  private restoreColumns(query:QueryResource, stubQuery:QueryResource, schema:QueryFormSchema) {
    const columns = stubQuery.columns
      .map((column) => (schema.columns.allowedValues as QueryColumn[]).find((candidate) => candidate.href === column.href))
      .filter((column):column is QueryColumn => column != null);

    query.columns.length = 0;
    columns.forEach((column) => query.columns.push(column));
  }

  private restoreSortBy(query:QueryResource, stubQuery:QueryResource, schema:QueryFormSchema) {
    const sortBys = stubQuery.sortBy
      .map((sortBy) => (schema.sortBy.allowedValues as QuerySortByResource[]).find((candidate) => candidate.href === sortBy.href))
      .filter((sortBy):sortBy is QuerySortByResource => sortBy != null);

    query.sortBy.length = 0;
    sortBys.forEach((sortBy) => query.sortBy.push(sortBy));
  }

  private restoreGroupBy(query:QueryResource, stubQuery:QueryResource, schema:QueryFormSchema) {
    const groupBy = (schema.groupBy.allowedValues as QueryGroupByResource[]).find(
      (candidate) => stubQuery.groupBy?.href === candidate.href,
    );

    query.groupBy = groupBy;
  }

  private restoreOtherProperties(query:QueryResource, stubQuery:QueryResource) {
    const source = stubQuery.$source as Record<string, unknown>;
    const links = (source._links ?? {}) as Record<string, unknown>;

    Object.keys(source)
      .filter((key) => key !== '_links' && key !== 'filters')
      .forEach((property) => {
        (query as Record<string, unknown>)[property] = (stubQuery as Record<string, unknown>)[property];
      });

    Object.keys(links)
      .filter((key) => key !== 'columns' && key !== 'groupBy' && key !== 'sortBy')
      .forEach((property) => {
        (query as Record<string, unknown>)[property] = (stubQuery as Record<string, unknown>)[property];
      });
  }
}
