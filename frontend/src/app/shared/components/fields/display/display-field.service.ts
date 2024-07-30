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

import { Injectable, Injector } from '@angular/core';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { AbstractFieldService, IFieldType } from 'core-app/shared/components/fields/field.service';
import { DisplayField } from 'core-app/shared/components/fields/display/display-field.module';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { MultipleLinesCustomOptionsDisplayField } from 'core-app/shared/components/fields/display/field-types/multiple-lines-custom-options-display-field.module';
import { MultipleLinesUserFieldModule } from 'core-app/shared/components/fields/display/field-types/multiple-lines-user-display-field.module';
import { ProgressTextDisplayField } from 'core-app/shared/components/fields/display/field-types/progress-text-display-field.module';
import { DateDisplayField } from 'core-app/shared/components/fields/display/field-types/date-display-field.module';

export interface IDisplayFieldType extends IFieldType<DisplayField> {
  new(resource:HalResource, attributeType:string, schema:IFieldSchema, context:DisplayFieldContext):DisplayField;
}

export interface DisplayFieldContext {
  /** The injector to use for the context of this field. Relevant for embedded service injection */
  injector:Injector;

  /** Where will the field be rendered? This may result in different styles (Multi select field, e.g.,) */
  container:'table'|'single-view'|'timeline';

  /** Options passed to the display field */
  options:{ [key:string]:any };
}

@Injectable({ providedIn: 'root' })
export class DisplayFieldService extends AbstractFieldService<DisplayField, IDisplayFieldType> {
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
  public getField(resource:HalResource, fieldName:string, schema:IFieldSchema, context:DisplayFieldContext):DisplayField {
    // We handle multi value fields differently in the single view context
    const instance = this.getFieldForContext(resource, fieldName, schema, context);
    instance.apply(resource, schema);
    return instance;
  }

  private getFieldForContext(resource:HalResource, fieldName:string, schema:IFieldSchema, context:DisplayFieldContext):DisplayField {
    // We handle multi value fields differently in the single view context
    const isCustomMultiLinesField = ['[]CustomOption'].indexOf(schema.type) >= 0;
    if (context.container === 'single-view' && isCustomMultiLinesField) {
      return new MultipleLinesCustomOptionsDisplayField(fieldName, context) as DisplayField;
    }
    // Separate class seems not needed (merge with []CustomOption above?)
    const isVersionMultiLinesField = ['[]Version'].indexOf(schema.type) >= 0;
    if (context.container === 'single-view' && isVersionMultiLinesField) {
      return new MultipleLinesCustomOptionsDisplayField(fieldName, context) as DisplayField;
    }
    const isUserMultiLinesField = ['[]User'].indexOf(schema.type) >= 0;
    if (context.container === 'single-view' && isUserMultiLinesField) {
      return new MultipleLinesUserFieldModule(fieldName, context) as DisplayField;
    }

    // We handle progress differently in the timeline
    if (context.container === 'timeline' && fieldName === 'percentageDone') {
      return new ProgressTextDisplayField(fieldName, context);
    }

    // We want to render an combined edit field but the display field must
    // show the original attribute
    if (context.container === 'table' && ['startDate', 'dueDate', 'date'].includes(fieldName)) {
      return new DateDisplayField(fieldName, context);
    }

    const cls = this.getSpecificClassFor(resource._type, fieldName, schema.type);

    // eslint-disable-next-line new-cap
    return new cls(fieldName, context) as DisplayField;
  }
}
