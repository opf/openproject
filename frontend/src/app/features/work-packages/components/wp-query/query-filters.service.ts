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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable, inject } from '@angular/core';
import { QueryFormResource } from 'core-app/features/hal/resources/query-form-resource';
import {
  QueryFilterInstanceSchemaResource,

} from 'core-app/features/hal/resources/query-filter-instance-schema-resource';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';

interface QueryFormSchemaProperties {
  filtersSchemas:{ elements:QueryFilterInstanceSchemaResource[] };
}

type QueryFormSchema = QueryFormResource['schema'] & QueryFormSchemaProperties;

@Injectable()
export class QueryFiltersService {
  protected schemaCache = inject(SchemaCacheService);


  /**
   * Get the matching schema of the filter resource
   * from the schema
   */
  private getFilterSchema(filter:QueryFilterInstanceResource, form:QueryFormResource):QueryFilterInstanceSchemaResource|undefined {
    const schema = form.schema as QueryFormSchema;
    const available = schema.filtersSchemas.elements;
    return available.find((schema) => schema.allowedFilterValue.href === filter.filter.href);
  }

  /**
   * Prepares the schemas of each filter to be readily placed to make alterations
   * to the filter based on the filter e.g. when sending an updated filter to the backend.
   * @param query
   * @param form
   */
  public mapSchemasIntoFilters(query:QueryResource, form:QueryFormResource) {
    query.filters.forEach((filter) => {
      const schema = this.getFilterSchema(filter, form)!;
      filter.$links.schema = schema.$links.self;
      this.schemaCache.update(filter, schema);
    });
  }

  public setSchemas(schemas:CollectionResource<QueryFilterInstanceSchemaResource>) {
    schemas.elements.forEach((schema) => {
      this.schemaCache.updateValue(schema.$links.self.href!, schema);
    });
  }
}
