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

import {HalResource} from '../../api/api-v3/hal-resources/hal-resource.service';
import {Field, FieldFactory} from '../../wp-field/wp-field.module';

export class DisplayField extends Field {
  public static type: string;
  public static $injector: ng.auto.IInjectorService;
  public I18n: op.I18n;
  public mode:string|null = null;

  public get isFormattable():boolean {
    return false;
  }

  public get value() {
    if (this.schema) {
      return this.resource[this.name];
    }
    else {
      return null;
    }
  }

  public get type(): string {
    return (this.constructor as typeof DisplayField).type;
  }

  public get valueString(): string {
    return this.value;
  }

  public get placeholder():string {
    return '-';
  }

  public get label() {
    return (this.schema.name || this.name);
  }

  protected get $injector(): ng.auto.IInjectorService {
    return (this.constructor as typeof DisplayField).$injector;
  }

  public render(element:HTMLElement, displayText:string): void {
    element.textContent = displayText;
  }

  constructor(public resource: HalResource,
              public name: string,
              public schema:op.FieldSchema) {
    super(resource, name, schema);

    this.I18n = <op.I18n>this.$injector.get('I18n');
  }
}

export class DisplayFieldFactory extends FieldFactory {

  protected static fields:{[field:string]: string} = {};
  protected static classes:{[type:string]: typeof DisplayField} = {};

  public static create(workPackage: HalResource,
                       fieldName: string,
                       schema: op.FieldSchema): DisplayField {
    let type = DisplayFieldFactory.getSpecificType(fieldName) ||
      schema && DisplayFieldFactory.getType(schema.type) ||
      DisplayFieldFactory.defaultType;
    let fieldClass = DisplayFieldFactory.classes[type];

    return (new fieldClass(workPackage, fieldName, schema)) as DisplayField;
  }

  protected static getSpecificType(type: string): string {
    let fields = DisplayFieldFactory.fields;

    return fields[type];
  }
}
