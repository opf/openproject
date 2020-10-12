// -- copyright
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
// ++

import {Injector} from '@angular/core';
import {Field} from "core-app/modules/fields/field.base";

export interface IFieldType<T extends Field> {
  fieldType:string;
  $injector:Injector;
  new(...args:any[]):T;
}

export abstract class AbstractFieldService<T extends Field, C extends IFieldType<T>> {
  /** Default field type to fall back to */
  public defaultFieldType:string;

  /** Registered attribute types => field identifier */
  protected fields:{[attributeType:string]:string} = {};

  /** Registered field classes */
  protected classes:{[type:string]:C} = {};

  /**
   * Get the field type for the given attribute type.
   * If no registered type exists for the field, returns the default type.
   *
   * @param {string} attributeType
   * @returns {string}
   */
  public fieldType(attributeType:string):string|undefined {
    return this.fields[attributeType];
  }

  /**
   * Get the Field class for the given field name.
   * Returns the default class if no registered type exists
   * @param {string} fieldName
   * @returns {C}
   */
  public getClassFor(fieldName:string, type:string = 'unknown'):C {
    let key = this.fieldType(fieldName) || this.fieldType(type) || this.defaultFieldType;
    return this.classes[key];
  }

  public getSpecificClassFor(resourceType:string, fieldName:string, type:string = 'unknown'):C {
    let key = this.fieldType(`${resourceType}-${fieldName}`) ||
              this.fieldType(`${resourceType}-${type}`);

    if (key) {
      return this.classes[key];
    }

    return this.getClassFor(fieldName, type);
  }

  /**
   * Add a field class for the given attribute names.
   *
   * @param fieldClass The field class
   * @param {string} fieldType the field type identifier (e.g., 'progress')
   * @param {string[]} attributes The schema attribute names to register for (e.g., 'Progress')
   *
   * @returns {this}
   */
  public addFieldType(fieldClass:any, fieldType:string, attributes:string[]) {
    fieldClass.fieldType = fieldType;
    this.register(fieldClass, attributes);

    return this;
  }

  /**
   * Add a field class for the given attribute names and a specify resource.
   *
   * @param resourceType The resource type (e.g Work Package)
   * @param fieldClass The field class
   * @param {string} fieldType the field type identifier (e.g., 'progress')
   * @param {string[]} attributes The schema attribute names to register for (e.g., 'Progress')
   *
   * @returns {this}
   */
  public addSpecificFieldType(resourceType:string, fieldClass:any, fieldType:string, attributes:string[]) {
    fieldClass.fieldType = `${resourceType}-${fieldType}`;
    attributes = attributes.map((attribute) => `${resourceType}-${attribute}`);
    this.register(fieldClass, attributes);

    return this;
  }

  /**
   * Register new schema attribute names for an existing field type
   *
   * @param {string} fieldType The field type to extend (e.g., 'select')
   * @param {string[]} attributes The attribute schema names to register to the existing fieldType (e.g., 'budget')
   *
   * @returns {this}
   */
  public extendFieldType(fieldType:string, attributes:string[]) {
    let fieldClass = this.classes[fieldType] || this.getClassFor(fieldType);
    return this.addFieldType(fieldClass, fieldType, attributes);
  }

  /**
   * Register the
   * @param {C} fieldClass
   * @param {string[]} fields
   */
  protected register(fieldClass:C, fields:string[] = []) {
    const type = fieldClass.fieldType;
    fields.forEach((field:string) => this.fields[field] = type);
    this.classes[type] = fieldClass;
  }
}
