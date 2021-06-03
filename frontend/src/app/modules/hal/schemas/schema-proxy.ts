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

import { SchemaResource } from "core-app/modules/hal/resources/schema-resource";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { IFieldSchema } from "core-app/modules/fields/field.base";

export interface ISchemaProxy extends SchemaResource {
  ofProperty(property:string):IFieldSchema;
  isAttributeEditable(property:string):boolean;
  isEditable:boolean;
}

export class SchemaProxy implements ProxyHandler<SchemaResource> {
  constructor(protected schema:SchemaResource,
              protected resource:HalResource) {
  }

  static create(schema:SchemaResource, resource:HalResource) {
    return new Proxy(
      schema,
      new this(schema, resource)
    ) as ISchemaProxy;
  }

  get(schema:SchemaResource, property:PropertyKey, receiver:any):any {
    switch (property) {
    case 'ofProperty': {
      return this.proxyMethod(this.ofProperty);
    }
    case 'isAttributeEditable': {
      return this.proxyMethod(this.isAttributeEditable);
    }
    case 'mappedName': {
      return this.proxyMethod(this.mappedName);
    }
    case 'isEditable': {
      return this.isEditable;
    }
    default: {
      return Reflect.get(schema, property, receiver);
    }
    }
  }

  /**
   * Returns the part of the schema relevant for the provided property.
   *
   * We use it to support the virtual attribute 'combinedDate' which is the combination of the three
   * attributes 'startDate', 'dueDate' and 'scheduleManually'. That combination exists only in the front end
   * and not on the native schema. As a property needs to be writable for us to allow the user editing,
   * we need to mark the writability positively if any of the combined properties are writable.
   *
   * @param property the schema part is desired for
   */
  public ofProperty(property:string):IFieldSchema|null {
    const propertySchema = this.schema[this.mappedName(property)];

    if (propertySchema) {
      return Object.assign({}, propertySchema, { writable: this.isEditable && propertySchema && propertySchema.writable });
    } else {
      return null;
    }
  }

  /**
   * Return whether the resource is editable with the user's permission
   * on the given resource package attribute.
   * In order to be editable, there needs to be an update link on the resource and the schema for
   * the attribute needs to indicate the writability.
   *
   * @param property
   */
  public isAttributeEditable(property:string):boolean {
    const propertySchema = this.ofProperty(property);

    return !!propertySchema && propertySchema.writable;
  }

  /**
   * Return whether the user in general has permission to edit the resource.
   * This check is required, but not sufficient to check all attribute restrictions.
   *
   * Use +isAttributeEditable(property)+ for this case.
   */
  public get isEditable() {
    return this.resource.isNew || !!this.resource.$links.update;
  }

  public mappedName(property:string):string {
    return property;
  }

  private proxyMethod(method:Function) {
    const self = this;

    // Returning a Proxy here so that the call is bound
    // to the SchemaProxy instance.
    return new Proxy(method, {
      apply: function (_, __, argumentsList) {
        return method.apply(self, [argumentsList[0]]);
      }
    });
  }
}
