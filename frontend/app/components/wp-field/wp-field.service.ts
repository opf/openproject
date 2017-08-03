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

import {FieldFactory} from './wp-field.module';
import {Field} from "./wp-field.module";
import {HalResource} from '../api/api-v3/hal-resources/hal-resource.service';

export class WorkPackageFieldService {
  public static get fieldFactory() {
    return FieldFactory;
  }

  public set defaultType(value:string) {
    (this.constructor as typeof WorkPackageFieldService).fieldFactory.defaultType = value;
  }

  constructor(protected $injector:ng.auto.IInjectorService) {
  }

  public getField(resource:any, fieldName:string, schema:op.FieldSchema):Field {
    return (this.constructor as typeof WorkPackageFieldService).fieldFactory.create(resource, fieldName, schema);
  }

  public fieldType(name:string):string {
    return (this.constructor as typeof WorkPackageFieldService).fieldFactory.getType(name);
  }

  public addFieldType(fieldClass:any, displayType:string, fields:string[]) {
    fieldClass.type = displayType;
    fieldClass.$injector = this.$injector;
    (this.constructor as typeof WorkPackageFieldService).fieldFactory.register(fieldClass, fields);
    return this;
  }

  public extendFieldType(displayType:string, fields:string[]) {
    var fieldClass = (this.constructor as typeof WorkPackageFieldService).fieldFactory.getClassFor(displayType);
    return this.addFieldType(fieldClass, displayType, fields);
  }
}

angular
  .module('openproject')
  .service('wpField', WorkPackageFieldService);
