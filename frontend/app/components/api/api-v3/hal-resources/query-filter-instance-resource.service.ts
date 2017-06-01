//-- copyright
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
//++

import {HalResource} from './hal-resource.service';
import {opApiModule} from '../../../../angular-modules';
import {QueryFilterResource} from './query-filter-resource.service';
import {QueryOperatorResource} from './query-operator-resource.service';
import {QueryFilterInstanceSchemaResource} from './query-filter-instance-schema-resource.service';

interface QueryFilterInstanceResourceEmbedded {
  filter: QueryFilterResource;
  schema: QueryFilterInstanceSchemaResource;
}

interface QueryFilterInstanceResourceLinks extends QueryFilterInstanceResourceEmbedded {
}

export class QueryFilterInstanceResource extends HalResource {

  public $embedded: QueryFilterInstanceResourceEmbedded;
  public $links: QueryFilterInstanceResourceLinks;

  public filter: QueryFilterResource;
  public operator: QueryOperatorResource;
  public values: HalResource[]|string[];
  public schema: QueryFilterInstanceSchemaResource;
  private memoizedCurrentSchemas: {[key: string]: QueryFilterInstanceSchemaResource} = {};

  public get id():string {
    return this.filter.id;
  }

  /**
   * Get the complete current schema.
   *
   * The filter instance's schema is made up of a static and a variable part.
   * The variable part depends on the currently selected operator.
   * Therefore, the schema differs based on the selected operator.
   */
  public get currentSchema():QueryFilterInstanceSchemaResource|null {
    if (!this.schema || !this.operator) {
      return null;
    }

    let key = this.operator.href!.toString();

    if (this.memoizedCurrentSchemas[key] === undefined) {
      this.memoizedCurrentSchemas[key] = this.schema.resultingSchema(this.operator);
    }

    return this.memoizedCurrentSchemas[key];
  }

  public static fromSchema(schema:QueryFilterInstanceSchemaResource):QueryFilterInstanceResource {
    let operator = (schema.operator.allowedValues as HalResource[])[0];
    let filter = (schema.filter.allowedValues as HalResource[])[0];
    let source:any = {
                        name: filter.name,
                       _links: {
                         filter: filter.$plain()._links.self,
                         schema: schema.$plain()._links.self,
                         operator: operator.$plain()._links.self
                       }
                     }

    if (this.definesAllowedValues(schema)) {
      source._links['values'] = [];
    } else {
      source['values'] = [];
    }

    let newFilter = new QueryFilterInstanceResource(source);

    newFilter.schema = schema;


    return newFilter;
  }

  public isCompletelyDefined() {
    return this.values.length || (this.currentSchema && !this.currentSchema.isValueRequired());
  }

  private static definesAllowedValues(schema:QueryFilterInstanceSchemaResource) {
    return _.some(schema._dependencies[0].dependencies,
                  (dependency:any) => dependency.values && dependency.values._links && dependency.values._links.allowedValues );
  }
}

function queryFilterInstanceResource() {
  return QueryFilterInstanceResource;
}

export interface QueryFilterInstanceResourceInterface extends QueryFilterInstanceResourceLinks, QueryFilterInstanceResource {
}

opApiModule.factory('QueryFilterInstanceResource', queryFilterInstanceResource);
