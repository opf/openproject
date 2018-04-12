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
import {initializeHalResource} from 'core-app/modules/hal/helpers/hal-resource-builder';

export interface HalResourceClass<T extends HalResource = HalResource> {
  new(injector:Injector,
      source:any,
      $loaded:boolean,
      halInitializer:(halResource:T) => void):T;
}

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
  public defaultClass():HalResourceClass<HalResource> {
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
  public createHalResource<T extends HalResource = HalResource>(source:any, loaded:boolean = true):T {
    if (_.isNil(source)) {
      source = HalResource.getEmptyResource();
    }

    const resourceClass = this.getResourceClassOfType<T>(source._type);
    return this.createHalResourceOfType<T>(resourceClass, source, loaded);
  }

  public createHalResourceOfType<T extends HalResource = HalResource>(resourceClass:HalResourceClass<T>, source:any, loaded:boolean = false) {
    // Create the initialization function
    const initializer = (instance:T) => initializeHalResource(instance, this, this.halLink);

    // Build the hal resource
    let instance = new resourceClass(this.injector, source, loaded, initializer);

    return instance;
  }

  /**
   * Create a HalResource from the copied source of the given, other HalResource.
   *
   * @param {HalResource} other
   * @returns A HalResource with the identitical copied source of other.
   */
  public copyResource<T extends HalResource>(other:T):T {
    const copy = _.cloneDeep(other.$source);
    return this.createHalResource<T>(copy, other.$loaded);
  }

  /**
   * Create a linked HalResource from the given link.
   *
   * @param {HalLinkInterface} link
   * @returns {HalResource}
   */
  public fromLink(link:HalLinkInterface) {
    const resource = HalResource.getEmptyResource(this.halLink.fromObject(link));
    return this.createHalResource(resource, false);
  }

  /**
   * Get a linked resource from its HalLink with the correct ype
   */
  public createLinkedResource(linkName:string, link:HalLinkInterface) {
    const source = HalResource.getEmptyResource();
    const type = this.constructor._type;
    source._links.self = link;

    const resourceClass = this.getResourceClassOfAttribute(type, linkName);
    return this.createHalResourceOfType(resourceClass, source, false);
  }

  /**
   * Get the configured resource class of a type.
   *
   * @param type
   * @returns {HalResource}
   */
  protected getResourceClassOfType<T extends HalResource>(type:string):HalResourceClass<T> {
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
  protected getResourceClassOfAttribute<T extends HalResource = HalResource>(type:string, attribute:string):HalResourceClass<T>|HalResourceClass<HalResource> {
    const typeConfig = this.config[type];
    const types = (typeConfig && typeConfig.attrTypes) || {};
    const resourceRef = types[attribute];

    if (resourceRef) {
      return this.getResourceClassOfType(resourceRef);
    }

    return this.defaultClass();
  }
}
