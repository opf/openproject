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

import {Injectable, Injector} from '@angular/core';
import {HalLinkService} from 'core-app/modules/hal/hal-link/hal-link.service';
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {
  halResourceDefaultConfig, HalResourceFactoryConfigInterface,
} from 'core-app/modules/hal/services/hal-resource-factory.config';
import {HalLinkInterface} from 'core-app/modules/hal/hal-link/hal-link';

@Injectable()
export class HalResourceFactoryService {

  /**
   * List of all known hal resources, extendable.
   */
  private config = halResourceDefaultConfig;

  constructor(readonly halLink:HalLinkService,
              readonly injector:Injector) {

  }

  /**
   * Register a HalResource for use with the API.
   * @param {HalResourceStatic} resource
   */
  public registerResource(key:string, entry:HalResourceFactoryConfigInterface) {
    this.config[key] = entry;
  }

  /**
   * Get the default class.
   * Initially, it's HalResource.
   *
   * @returns {HalResource}
   */
  public get defaultClass() {
    return HalResource;
  }

  /**
   * Create a HalResource from a source object.
   * If a _type attribute is defined and the type is configured, the
   * respective class will be used for instantiation.
   *
   * @param source
   * @returns {HalResource}
   */
  public createHalResource(source:any, loaded:boolean = false, force:boolean = false):HalResource|null {
    if (_.isNil(source)) {
      return null;
    }

    if (!force && !(source._embedded || source._links)) {
      return source;
    }

    const resourceClass = this.getResourceClassOfType(source._type);
    return new resourceClass(this.injector, source);
  }

  /**
   * Create a linked HalResource from the given link.
   *
   * @param {HalLinkInterface} link
   * @returns {HalResource}
   */
  public fromLink(link:HalLinkInterface) {
    const resource = HalResource.getEmptyResource(this.halLink.fromObject(link));
    return new HalResource(this.injector, resource, false);
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
    return new resourceClass(this.injector, source, false);
  }

  /**
   * Get the configured resource class of a type.
   *
   * @param type
   * @returns {HalResource}
   */
  protected getResourceClassOfType(type:string):typeof HalResource {
    const config = this.config[type];
    return (config && config.cls) ? config.cls : this.defaultClass;
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
    const typeConfig = this.config[type];
    const types = (typeConfig && typeConfig.attrTypes) || {};
    const resourceRef = types[attribute];

    if (resourceRef) {
      return this.getResourceClassOfType(resourceRef);
    }

    return this.defaultClass;
  }
}
