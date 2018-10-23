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

import {Injectable, Injector} from '@angular/core';
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {AbstractFieldService, IFieldType} from "core-app/modules/fields/field.service";
import {DisplayField} from "core-app/modules/fields/display/display-field.module";
import {IFieldSchema} from "core-app/modules/fields/field.base";

export interface IDisplayFieldType extends IFieldType<DisplayField> {
  new(resource:HalResource, attributeType:string, schema:IFieldSchema, context:DisplayFieldContext):DisplayField;
}

export interface DisplayFieldContext {
  /** Where will the field be rendered? This may result in different styles (Multi select field, e.g.,) */
  container: 'table'|'single-view'|'timeline';

  /** Options passed to the display field */
  options:{ [key:string]:any };
}

@Injectable()
export class DisplayFieldService extends AbstractFieldService<DisplayField, IDisplayFieldType> {

  constructor(injector:Injector) {
    super(injector);
  }

  /**
   * Create an instance of the field type T given the required arguments
   * with either in descending order:
   *
   *  1. The registered field name (most specific)
   *  2. The registered field for the schema attribute type
   *  3. The default field type
   *
   * @param resource
   * @param {string} fieldName
   * @param {IFieldSchema} schema
   * @param {string} context
   * @returns {T}
   */
  public getField(resource:any, fieldName:string, schema:IFieldSchema, context:DisplayFieldContext):DisplayField {
    const fieldClass = this.getClassFor(fieldName, schema.type);
    return new fieldClass(resource, fieldName, schema, context);
  }
}
