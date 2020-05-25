//-- copyright
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
//++

import {InputState} from "reactivestates";
import {HalLinkInterface} from 'core-app/modules/hal/hal-link/hal-link';
import {Injector} from '@angular/core';
import {States} from 'core-components/states.service';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export interface HalResourceClass<T extends HalResource = HalResource> {
  new(injector:Injector,
      source:any,
      $loaded:boolean,
      halInitializer:(halResource:T) => void,
      $halType:string):T;
}

export class HalResource {
  // TODO this is the source of many issues in the frontend
  // because it no longer properly type checks stuff
  // Since 2019-10-21 I'm documenting what bugs this caused:
  // https://community.openproject.com/wp/31462
  [attribute:string]:any;

  // The API type reported from API
  public _type:string;

  // Internal initialization time for objects
  // created in the frontend
  public __initialized_at:Number;

  // The HalResource that this type maps to
  // This will almost always be equal to _type, however may be different for dynamic types
  // e.g., { _type: 'StatusFilterInstance', $halType: 'QueryFilterInstance' }.
  //
  // This is required for attributes to be correctly mapped according to their configuration.
  public $halType:string;

  @InjectField() states:States;
  @InjectField() I18n:I18nService;

  /**
   * Constructs and initializes the HalResource. For this, the halResoureFactory is required.
   *
   * However, We can't inject the HalResourceFactory here because it itself depends on this class.
   * So if you need to initialize a HalResource, use +HalResourceFactory.createHalResource+ instead.
   *
   * @param {Injector} injector
   * @param $halType The HalResource type that this instance maps to
   * @param $source
   * @param {boolean} $loaded
   * @param {Function} initializer The initializer callback to HAL-transform all linked and embedded resources.
   *
   */
  public constructor(public injector:Injector,
                     public $source:any,
                     public $loaded:boolean,
                     public halInitializer:(halResource:any) => void,
                     $halType:string) {
    this.$halType = $halType;
    this.$initialize($source);
  }

  public static getEmptyResource(self:{ href:string|null } = {href: null}):any {
    return {_links: {self: self}};
  }

  public $links:any = {};
  public $embedded:any = {};
  public $self:Promise<this>;

  public _name:string;

  public static idFromLink(href:string):string {
    return href.split('/').pop()!;
  }

  public get idFromLink():string {
    if (this.$href) {
      return HalResource.idFromLink(this.$href);
    }

    return '';
  }

  public $initialize(source:any) {
    this.$source = source.$source || source;
    this.halInitializer(this);
  }

  /**
   * Override toString to ensure the resource can
   * be printed nicely on console and in errors
   */
  public toString() {
    if (this.$href) {
      return `[HalResource href=${this.$href}]`;
    } else {
      return `[HalResource id=${this.id}]`;
    }
  }

  /**
   * Returns the ID and ensures it's a string, null.
   * Returns a string when:
   *  - The embedded ID is actually set
   *  - The self link is terminated by a number.
   */
  public get id():string|null {
    if (this.$source.id) {
      return this.$source.id.toString();
    }

    const id = this.idFromLink;
    if (id.match(/^\d+$/)) {
      return id;
    }

    return null;
  }

  public set id(val:string|null) {
    this.$source.id = val;
  }

  public get isNew():boolean {
    return this.id === 'new';
  }

  public get persisted() {
    return !!(this.id && this.id !== 'new');
  }

  /**
   * Return whether the resource is editable with the user's permission
   * on the given resource package attribute.
   * In order to be editable, there needs to be an update link on the resource and the schema for
   * the attribute needs to indicate the writability.
   *
   * @param property
   */
  public isAttributeEditable(property:string):boolean {
    const fieldSchema = this.schema[property];
    return this.$links.update && fieldSchema && fieldSchema.writable;
  }

  /**
   * Retain the internal tracking identifier from the given other work package.
   * This is due to us needing to identify a work package beyond its actual ID,
   * because that changes upon saving.
   *
   * @param other
   */
  public retainFrom(other:HalResource) {
    this.__initialized_at = other.__initialized_at;
  }


  /**
   * Create a HalResource from the copied source of the given, other HalResource.
   *
   * @param {HalResource} other
   * @returns A HalResource with the identitical copied source of other.
   */
  public $copy<T extends HalResource = HalResource>(source:Object = {}):T {
    let clone:HalResourceClass<T> = this.constructor as any;

    return new clone(this.injector, _.merge(this.$plain(), source), this.$loaded, this.halInitializer, this.$halType);
  }

  public $plain():any {
    return _.cloneDeep(this.$source);
  }

  public get $isHal():boolean {
    return true;
  }

  public get $link():HalLinkInterface {
    return this.$links.self.$link;
  }

  public get name():string {
    return this._name || this.$link.title || '';
  }

  public set name(name:string) {
    this._name = name;
  }

  /**
   * Alias for $href.
   */
  public get href():string|null {
    return this.$link.href;
  }

  public get $href():string|null {
    return this.$link.href;
  }

  /**
   * Return the associated state to this HAL resource, if any.
   */
  public get state():InputState<this>|null {
    return null;
  }

  /**
   * Update the state
   */
  public push(newValue:this):Promise<unknown> {
    if (this.state) {
      this.state.putValue(newValue);
    }

    return Promise.resolve();
  }

  public previewPath():string|undefined {
    if (this.isNew && this.project) {
      return this.project.href;
    }

    return undefined;
  }

  public getEditorTypeFor(_fieldName:string):'full'|'constrained' {
    return 'constrained';
  }

  public $load(force = false):Promise<this> {
    if (!this.state) {
      return this.$loadResource(force);
    }

    const state = this.state;

    if (force) {
      state.clear();
    }

    // If nobody has asked yet for the resource to be $loaded, do it ourselves.
    // Otherwise, we risk returning a promise, that will never be resolved.
    state.putFromPromiseIfPristine(() => this.$loadResource(force));

    return <Promise<this>>state.valuesPromise().then((source:any) => {
      this.$initialize(source);
      this.$loaded = true;
      return this;
    });
  }

  protected $loadResource(force = false):Promise<this> {
    if (!force) {
      if (this.$loaded) {
        return Promise.resolve(this);
      }

      if (!this.$loaded && this.$self) {
        return this.$self;
      }
    }

    // Reset and load this resource
    this.$loaded = false;
    this.$self = this.$links.self({}).then((source:any) => {
      this.$loaded = true;
      this.$initialize(source.$source);
      return this;
    });

    return this.$self;
  }

  /**
   * Update the resource ignoring the cache.
   */
  public $update() {
    return this.$load(true);
  }

  /**
   * Specify this resource's embedded keys that should be transformed with resources.
   * Use this to restrict, e.g., links that should not be made properties if you have a custom get/setter.
   */
  public $embeddableKeys():string[] {
    const properties = Object.keys(this.$source);
    return _.without(properties, '_links', '_embedded', 'id');
  }

  /**
   * Specify this resource's keys that should not be transformed with resources.
   * Use this to restrict, e.g., links that should not be made properties if you have a custom get/setter.
   */
  public $linkableKeys():string[] {
    const properties = Object.keys(this.$links);
    return _.without(properties, 'self');
  }
}
