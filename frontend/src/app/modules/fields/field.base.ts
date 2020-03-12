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

import {DisplayFieldContext} from "core-app/modules/fields/display/display-field.service";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";

export interface IFieldSchema {
  type:string;
  writable:boolean;
  allowedValues?:any;
  required?:boolean;
  hasDefault:boolean;
  name?:string;
  options?:any;
}

export class Field extends UntilDestroyedMixin {
  public static type:string;
  public resource:any;
  public name:string;
  public schema:IFieldSchema;
  public context:DisplayFieldContext;

  public get displayName():string {
    return this.schema.name || this.name;
  }

  public get value() {
    return this.resource[this.name];
  }

  public get type():string {
    return (this.constructor as typeof Field).type;
  }

  public get required():boolean {
    return !!this.schema.required;
  }

  public get writable():boolean {
    return this.schema.writable && this.resource.isAttributeEditable(this.name);
  }

  public get hasDefault():boolean {
    return this.schema.hasDefault;
  }

  public get options():boolean {
    return this.schema.options;
  }

  public isEmpty():boolean {
    return !this.value;
  }

  public get unknownAttribute():boolean {
    return this.isEmpty && !this.schema;
  }
}
