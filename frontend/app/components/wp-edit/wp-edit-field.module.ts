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

export class Field {
  public static type:string;
  public static $injector:ng.auto.IInjectorService;

  protected constructor: typeof Field;

  public get value() {
    return this.resource[this.name];
  }

  public get type():string {
    return this.constructor.type;
  }

  protected get $injector():ng.auto.IInjectorService {
    return this.constructor.$injector;
  }

  constructor(public resource:op.HalTransformed,
              public name:string,
              public schema) {
  }
}

export class FieldFactory {
  public static defaultType:string;

  protected static fields = {};

  /**
   * A map of field constructor objects.
   * @type {{}}
   */
  protected static classes: {[type:string]: typeof Field} = {};

  /**
   * Register a class that will be used for a certain field type.
   * The static type property of the class indicates for which field type it
   * will be used.
   * @param fieldClass
   * @param fields
   */
  public static register(fieldClass: typeof Field, fields:string[] = []) {
    fields.forEach(field => FieldFactory.fields[field] = fieldClass.type);
    FieldFactory.classes[fieldClass.type] = fieldClass;
  }

  /**
   * Return a Field instance.
   * The class is registered in FieldFactory#register.
   * @param workPackage
   * @param fieldName
   * @param schema
   * @returns {Field}
   */
  public static create(workPackage:op.WorkPackage,
                       fieldName:string,
                       schema:op.FieldSchema):Field {
    let type = FieldFactory.getType(schema.type);
    let fieldClass = FieldFactory.classes[type];

    return new fieldClass(workPackage, fieldName, schema);
  }

  /**
   * Return the field type or the default type if none is given.
   * @param type
   * @returns {string}
   */
  protected static getType(type:string):string {
    let fields = FieldFactory.fields;
    let defaultType = FieldFactory.defaultType;

    return fields[type] || defaultType;
  }
}
