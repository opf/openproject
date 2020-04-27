//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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

import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {QueryFilterResource} from 'core-app/modules/hal/resources/query-filter-resource';
import {QueryFilterInstanceSchemaResource} from 'core-app/modules/hal/resources/query-filter-instance-schema-resource';
import {QueryOperatorResource} from 'core-app/modules/hal/resources/query-operator-resource';

export class QueryFilterInstanceResource extends HalResource {
  public filter:QueryFilterResource;
  public operator:QueryOperatorResource;
  public values:HalResource[]|string[];
  public schema:QueryFilterInstanceSchemaResource;
  private memoizedCurrentSchemas:{ [key:string]:QueryFilterInstanceSchemaResource } = {};

  /**
   * Create a copied filter, taking over the manually set schema instance.
   */
  public $copy<T extends HalResource = HalResource>():T {
    let clone = super.$copy<T>() as any;
    clone.schema = this.schema;

    return clone;
  }

  public get id():string {
    return this.filter.id;
  }

  public get name():string {
    return this.filter.name;
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

  public isCompletelyDefined() {
    return this.values.length || (this.currentSchema && !this.currentSchema.isValueRequired());
  }

  public findOperator(operatorSymbol:string):QueryOperatorResource|undefined {
    return _.find(this.schema.availableOperators, (operator:QueryOperatorResource) => operator.id === operatorSymbol) as QueryOperatorResource|undefined;
  }
}
