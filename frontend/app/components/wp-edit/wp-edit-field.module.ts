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
//TODO: Add tests for all child classes
//TODO: Add type definitions for the respective field schemas
class Field implements op.EditField{
  public static type:string;

  protected constructor: typeof Field;

  public get value() {
    return this.resource[this.name];
  }

  public get type():string {
    return this.constructor.type;
  }

  constructor(public resource:op.HalTransformedElement,
              public name:string,
              public schema) {
  }
}

class TextField extends Field {
  public static type:string = 'text';
}

class SelectField extends Field {
  public static type:string = 'select';

  //TODO: Use allowedValue type instead of any
  public allowedValues:any[];

  constructor(workPackage, fieldName, schema) {
    super(workPackage, fieldName, schema);
    this.allowedValues = this.schema.embedded.allowedValues.map(value => value.data());
  }
}

//TODO: Implement
class DateField extends Field {}

//TODO: Implement
class DateRangeField extends Field {}

//TODO: Implement
class IntegerField extends Field {}

//TODO: Implement
class FloatField extends Field {}

//TODO: Implement
class BooleanField extends Field {}

//TODO: Implement
class DurationField extends Field {}

//TODO: Implement
class TextareaField extends Field {}

//TODO: See file wp-field.service.js:getInplaceEditStrategy for more eventual classes

//TODO: Add tests
export class FieldFactory {
  //TODO: Make the default type configurable
  protected static defaultType:string = 'text';

  //TODO: Make the type mapping configurable
  protected static types = {
    String: 'text',
    Priority: 'select',
    Status: 'select',
    Type: 'select'
  };

  /**
   * A map of field constructor objects.
   * @type {{}} TODO: Add type description
   */
  protected static classes: {[type:string]: typeof Field} = {};

  /**
   * Register a class that will be used for a certain field type.
   * The static type property of the class indicates for which field type it
   * will be used.
   * @param fieldClass
   */
  public static register(fieldClass: typeof Field) {
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
  public static create(workPackage:op.WorkPackage, fieldName:string, schema:op.FieldSchema):Field {
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
    let types = FieldFactory.types;
    let defaultType = FieldFactory.defaultType;

    return types[type] || defaultType;
  }
}

FieldFactory.register(TextField);
FieldFactory.register(SelectField);
