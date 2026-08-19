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

import { SchemaProxy } from 'core-app/features/hal/schemas/schema-proxy';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { StatusResource } from 'core-app/features/hal/resources/status-resource';

export class WorkPackageSchemaProxy extends SchemaProxy {
  get(schema:SchemaResource, property:PropertyKey, receiver:any):any {
    switch (property) {
      case 'isMilestone': {
        return this.isMilestone;
      }
      case 'isReadonly': {
        return this.isReadonly;
      }
      default: {
        return super.get(schema, property, receiver);
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
  public ofProperty(property:string) {
    if (property === 'combinedDate') {
      const propertySchema = super.ofProperty('startDate');

      if (!propertySchema) {
        return null;
      }

      propertySchema.writable = propertySchema.writable
        || this.isAttributeEditable('dueDate')
        || this.isAttributeEditable('scheduleManually');

      return propertySchema;
    }
    return super.ofProperty(property);
  }

  public get isReadonly():boolean {
    return (this.resource.readonly as boolean) || !!(this.resource.status as StatusResource|null)?.isReadonly;
  }

  /**
   * Return whether the work package is editable with the user's permission
   * on the given work package attribute.
   *
   * @param property
   */
  public isAttributeEditable(property:string):boolean {
    if (this.isReadonly && property !== 'status') {
      return false;
    } if (['startDate', 'dueDate', 'date'].includes(property)
      && this.resource.scheduleManually) {
      // This is a blatant shortcut but should be adequate.
      return super.isAttributeEditable('scheduleManually');
    }
    return super.isAttributeEditable(property);
  }

  public get isMilestone():boolean {
    return this.schema.hasOwnProperty('date');
  }

  public mappedName(property:string):string {
    if (this.isMilestone && (property === 'startDate' || property === 'dueDate')) {
      return 'date';
    }
    return property;
  }
}
