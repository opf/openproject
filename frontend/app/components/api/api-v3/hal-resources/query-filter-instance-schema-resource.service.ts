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

import {opApiModule} from '../../../../angular-modules';
import {SchemaResource, SchemaAttributeObject} from './schema-resource.service';
import {HalResource} from './hal-resource.service';
import {QueryFilterResource} from './query-filter-resource.service';
import {QueryOperatorResource} from './query-operator-resource.service';
import {SchemaDependencyResource} from './schema-dependency-resource.service'

var $q:ng.IQService;

interface QueryFilterInstanceSchemaResourceEmbedded {
}

interface QueryFilterInstanceSchemaResourceLinks {
  filter:QueryFilterResource;
}

export class QueryFilterInstanceSchemaResource extends SchemaResource {

  public $embedded: QueryFilterInstanceSchemaResourceEmbedded;
  public $links: QueryFilterInstanceSchemaResourceLinks;

  public operator:SchemaAttributeObject;
  public filter:SchemaAttributeObject;
  public dependency:SchemaDependencyResource;
  public values:SchemaAttributeObject|null;

  public get availableOperators() {
    return this.operator.allowedValues;
  }

  public $initialize(source:any) {
    super.$initialize(source);

    if (source._dependencies) {
      this.dependency = new SchemaDependencyResource(source._dependencies[0]);
    }
  }

  public isValueRequired():boolean {
    return !!(this.values);
  }

  public isResourceValue():boolean {
    return !!(this.values && this.values.allowedValues);
  }

  public resultingSchema(operator:QueryOperatorResource):QueryFilterInstanceSchemaResource {
    let staticSchema = this.$source;
    let dependentSchema = this.dependency.forValue(operator.href!.toString());
    let resultingSchema = {};

    _.merge(resultingSchema, staticSchema, dependentSchema);

    return new QueryFilterInstanceSchemaResource(resultingSchema);
  }
}

function qfisResource() {
  return QueryFilterInstanceSchemaResource;
}

export interface QueryFilterInstanceSchemaResourceInterface extends QueryFilterInstanceSchemaResource {
}

opApiModule.factory('QueryFilterInstanceSchemaResource', qfisResource);
