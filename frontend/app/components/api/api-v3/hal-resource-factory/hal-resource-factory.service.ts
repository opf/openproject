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

interface HalResourceFactoryConfigInterface {
  cls?:typeof HalResource;
  attrCls?:{[attrName:string]:typeof HalResource};
}

export class HalResourceFactoryService {
  protected config:{[typeName:string]:HalResourceFactoryConfigInterface} = {};

  /**
   * Get the default class.
   * Initially, it's HalResource.
   *
   * @returns {HalResource}
   */
  public get defaultClass() {
    return this.getResourceClassOfType('__default__');
  }

  /**
   * Set the default class.
   *
   * @param cls
   */
  public set defaultClass(cls:typeof HalResource) {
    this.setResourceType('__default__', cls);
  }

  /**
   * Configure the resource class for a resource type.
   *
   * @param typeName
   * @param cls
   */
  public setResourceType(typeName:string, cls:typeof HalResource) {
    cls._type = typeName;
    this.config[typeName] = {
      cls: cls,
      attrCls: {}
    };
  }

  /**
   * Set the attribute configuration for a certain type.
   *
   * @param typeName
   * @param attrTypes
   */
  public setResourceTypeAttributes(typeName:string, attrTypes:any) {
    Object.keys(attrTypes).forEach(attrName => {
      attrTypes[attrName] = this.getResourceClassOfType(attrTypes[attrName]);
    });

    if (!this.config[typeName]) {
      this.config[typeName] = {};
    }

    this.config[typeName].attrCls = attrTypes;
  }

  /**
   * Create a HalResource from a source object.
   * If a _type attribute is defined and the type is configured, the
   * respective class will be used for instantiation.
   *
   * @param source
   * @returns {HalResource}
   */
  public createHalResource(source:any):HalResource {
    const resourceClass = this.getResourceClassOfType(source._type);
    return new resourceClass(source);
  }

  /**
   * Create an unloaded HalResource that is a linked property of its parent.
   *
   * @param source
   * @param parentType
   * @param linkName
   */
  public createLinkedHalResource(source:any, parentType:string, linkName:string):HalResource {
    const resourceClass = this.getResourceClassOfAttribute(parentType, linkName);
    return new resourceClass(source, false);
  }

  /**
   * Get the configured resource class of a type.
   *
   * @param type
   * @returns {HalResource}
   */
  protected getResourceClassOfType(type:string):typeof HalResource {
    return this.getTypeConfig(type).cls as typeof HalResource;
  }

  /**
   * Get the resource class for an attribute.
   * Return the default class, if it does not exist.
   *
   * @param type
   * @param attribute
   * @returns {any}
   */
  protected getResourceClassOfAttribute(type:string, attribute:string):typeof HalResource {
    const typeConfig = this.getTypeConfig(type);
    const resourceClass = (typeConfig.attrCls as any)[attribute];

    if (resourceClass) {
      return resourceClass;
    }

    return this.defaultClass;
  }

  /**
   * Get the string of the type or the default string, if it doesn't exist.
   *
   * @param type
   * @returns {string}
   */
  protected getType(type:string):string {
    return this.config[type] ? type : '__default__';
  }

  /**
   * Get the type config for a certain type.
   * Return the default config, if it doesn't exist.
   *
   * @param type
   * @returns {any}
   */
  protected getTypeConfig(type:string):HalResourceFactoryConfigInterface {
    return this.config[this.getType(type)];
  }
}

opApiModule.service('halResourceFactory', HalResourceFactoryService);
