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


import {opApiModule} from '../../../../angular-modules';
import {HalResource} from '../hal-resources/hal-resource.service';

export class HalResourceFactoryService {
  private config:any = {};

  public get defaultClass() {
    return this.config.__default__.cls;
  }

  public set defaultClass(cls:typeof HalResource) {
    this.setResourceType('__default__', cls);
  }

  public setResourceType(typeName:string, cls:typeof HalResource) {
    cls._type = typeName;
    this.config[typeName] = {
      cls: cls,
      attrCls: {}
    };
  }

  public setResourceTypeAttributes(typeName:string, attrTypes) {
    Object.keys(attrTypes).forEach(attrName => {
      attrTypes[attrName] = this.getResourceClassOfType(attrTypes[attrName]);
    });

    this.config[typeName].attrCls = attrTypes;
  }

  public getResourceClassOfType(type:string) {
    return this.getTypeConfig(type).cls;
  }

  public getResourceClassOfAttribute(type:string, attribute:string) {
    const typeConfig = this.getTypeConfig(type);
    const resourceClass = typeConfig.attrCls[attribute];

    if (resourceClass) {
      return resourceClass;
    }
    return this.getResourceClassOfType('__default__');
  }

  protected getType(type:string):string {
    return this.config[type] ? type : '__default__';
  }

  protected getTypeConfig(type:string) {
    return this.config[this.getType(type)];
  }
}

opApiModule.service('halResourceFactory', HalResourceFactoryService);
