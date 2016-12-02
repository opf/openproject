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

import {HalResource} from '../api/api-v3/hal-resources/hal-resource.service';

export class Field {
  public static type:string;
  public static $injector:ng.auto.IInjectorService;

  public get value() {
    return this.resource[this.name];
  }

  public set value(value) {
    this.resource[this.name] = value;
  }

  public get type():string {
    return (this.constructor as typeof Field).type;
  }

  public get required():boolean {
    return this.schema.required;
  }

  public get visibility():string {
    return this.schema.visibility;
  }

  public get hidden():boolean {
    return this.visibility === 'hidden';
  } 

  public isEmpty():boolean {
    return !this.value;
  }

  protected get $injector():ng.auto.IInjectorService {
    return (this.constructor as typeof Field).$injector;
  }

  protected $inject(name):any {
    return this.$injector.get(name);
  }

  constructor(public resource:HalResource,
              public name:string,
              public schema) {
  }
}

export class FieldFactory {
  public static defaultType:string;

  protected static fields = {};
  protected static classes = {};

  public static register(fieldClass:typeof Field, fields:string[] = []) {
    fields.forEach(field => this.fields[field] = fieldClass.type);
    this.classes[fieldClass.type] = fieldClass;
  }

  public static create(workPackage:HalResource,
                       fieldName:string,
                       schema:op.FieldSchema):Field {
    let type = this.getType(schema.type);
    let fieldClass = this.classes[type];

    return new fieldClass(workPackage, fieldName, schema);
  }

  public static getClassFor(fieldName:string):typeof Field {
    return this.classes[fieldName];
  }

  public static getType(type:string):string {
    let fields = this.fields;
    let defaultType = this.defaultType;

    return fields[type] || defaultType;
  }
}
