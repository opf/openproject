//-- copyright
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
//++

import {InputState} from "reactivestates";
import {opApiModule} from "../../../../angular-modules";
import {HalLink, HalLinkInterface} from "../hal-link/hal-link.service";
import {HalResourceFactoryService} from "../hal-resource-factory/hal-resource-factory.service";

const ObservableArray:any = require('observable-array');

var $q:ng.IQService;
var lazy:Function;
var halLink:typeof HalLink;
var halResourceFactory:HalResourceFactoryService;
var CacheService:any;

export class HalResource {
  [attribute:string]:any;
  public _type:string;

  public static create(element:any, force:boolean = false) {
    if (_.isNil(element)) {
      return element;
    }


    if (!force && !(element._embedded || element._links)) {
      return element;
    }

    return halResourceFactory.createHalResource(element);
  }

  public static fromLink(link:HalLinkInterface) {
    const resource = HalResource.getEmptyResource(halLink.fromObject(link));
    return new HalResource(resource, false);
  }

  public static getEmptyResource(self:{href:string|null} = {href: null}):any {
    return {_links: {self: self}};
  }

  public $links:any = {};
  public $embedded:any = {};
  public $self:ng.IPromise<HalResource>;

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
   * Please use $href instead.
   *
   * @deprecated
   */
  public get href():string|null {
    return this.$link.href;
  }

  public get $href():string|null {
    return this.$link.href;
  }

  constructor(public $source:any = HalResource.getEmptyResource(),
              public $loaded:boolean = true) {
    this.$initialize($source);
  }

  /**
   * Return the associated state to this HAL resource, if any.
   */
  public get state(): InputState<HalResource> | null {
    return null;
  }

  public $load(force = false):ng.IPromise<HalResource> {
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

    return <ng.IPromise<HalResource>> state.valuesPromise().then(source => {
      this.$initialize(source);
      this.$loaded = true;
      return this;
    });
  }

  protected $loadResource(force = false):ng.IPromise<HalResource> {
    if (!force) {
      if (this.$loaded) {
        return $q.when(this);
      }

      if (!this.$loaded && this.$self) {
        return this.$self;
      }
    }

    // HACK: Remove cleared promise key from cache.
    // We should not be so clever as to do that, instead, rewrite this with states.
    if (force) {
      CacheService.clearPromisedKey(this.$links.self.href);
    }
    // Reset and load this resource
    this.$loaded = false;
    this.$self = this.$links.self({}, this.$loadHeaders(force)).then((source:any) => {
      this.$loaded = true;
      this.$initialize(source);
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

  public $plain() {
    return angular.copy(this.$source);
  }

  public $copy() {
    let clone:any = this.constructor
    return new clone(_.cloneDeep(this.$source), this.$loaded);;
  }

  public $initialize(source:any) {
    this.$source = source.$source || source;
    initializeResource(this);
  }

  /**
   * $load by default uses the $http cache. This will likely be replaced by
   the HAL cache, but while it lasts, it should be ignored when using
   force.
   */
  protected $loadHeaders(force:boolean) {
    var headers:any = {};

    if (force) {
      headers.caching = {enabled: false};
    }

    return headers;
  }

  /**
   * Specify this resource's embedded keys that should be transformed with resources.
   * Use this to restrict, e.g., links that should not be made properties if you have a custom get/setter.
  */
  public $embeddableKeys():string[] {
    const properties = Object.keys(this.$source);
    return _.without(properties, '_links', '_embedded');
  }

  /**
   * Specify this resource's keys that should not be transformed with resources.
   * Use this to restrict, e.g., links that should not be made properties if you have a custom get/setter.
  */
  public $linkableKeys():string[] {
    const properties = Object.keys(this.$links);
    return _.without(properties, 'self');
  }

  /**
   * Get a linked resource from its HalLink with the correct ype
   */
  public createLinkedResource(linkName:string, link:HalLinkInterface) {
    const resource = HalResource.getEmptyResource();
    const type = this.constructor._type;
    resource._links.self = link;

    return halResourceFactory.createLinkedHalResource(resource, type, linkName);
  }
}

function initializeResource(halResource:HalResource) {
  setSource();
  setupLinks();
  setupEmbedded();
  proxyProperties();
  setLinksAsProperties();
  setEmbeddedAsProperties();

  function setSource() {
    if (!halResource.$source._links) {
      halResource.$source._links = {};
    }

    if (!halResource.$source._links.self) {
      halResource.$source._links.self = new HalLink();
    }
  }

  function proxyProperties() {
    halResource.$embeddableKeys().forEach((property:any) => {
      Object.defineProperty(halResource, property, {
        get() {
          return halResource.$source[property];
        },

        set(value) {
          halResource.$source[property] = value;
        },

        enumerable: true,
        configurable: true
      });
    });
  }

  function setLinksAsProperties() {
    halResource.$linkableKeys().forEach((linkName:string) => {
      lazy(halResource, linkName,
        () => {
          const link:any = halResource.$links[linkName].$link || halResource.$links[linkName];

          if (Array.isArray(link)) {
            var items = link.map(item => halResource.createLinkedResource(linkName, item.$link));
            var property:HalResource[] = new ObservableArray(...items).on('change', () => {
              property.forEach(item => {
                if (!item.$link) {
                  property.splice(property.indexOf(item), 1);
                }
              });

              halResource.$source._links[linkName] = property.map(item => item.$link);
            });

            return property;
          }

          if (link.href) {
            if (link.method !== 'get') {
              return HalLink.callable(link);
            }

            return halResource.createLinkedResource(linkName, link);
          }

          return null;
        },
        (val:any) => setter(val, linkName)
      );
    });
  }

  function setEmbeddedAsProperties() {
    if (!halResource.$source._embedded) {
      return;
    }

    Object.keys(halResource.$source._embedded).forEach(name => {
      lazy(halResource, name, () => halResource.$embedded[name], (val:any) => setter(val, name));
    });
  }

  function setupProperty(name:string, callback:(element:any) => any) {
    const instanceName = '$' + name;
    const sourceName = '_' + name;
    const sourceObj = halResource.$source[sourceName];

    if (angular.isObject(sourceObj)) {
      Object.keys(sourceObj).forEach(propName => {
        lazy((halResource as any)[instanceName], propName, () => callback(sourceObj[propName]));
      });
    }
  }

  function setupLinks() {
    setupProperty('links',
      link => Array.isArray(link) ? link.map(HalLink.callable) : HalLink.callable(link));
  }

  function setupEmbedded() {
    setupProperty('embedded', element => {
      angular.forEach(element, (child:any, name:string) => {
        if (child && (child._embedded || child._links)) {
          lazy(element, name, () => HalResource.create(child));
        }
      });

      if (Array.isArray(element)) {
        return element.map((source) => HalResource.create(source, true));
      }

      return HalResource.create(element);
    });
  }

  function setter(val:HalResource|{ href?: string }, linkName:string) {
    if (!val) {
      halResource.$source._links[linkName] = {href: null};
    } else if (_.isArray(val)) {
      halResource.$source._links[linkName] = val.map((el:any) => { return {href: el.href} });
    } else if (val.hasOwnProperty('$link')) {
      const link = (val as HalResource).$link;

      if (link.href) {
        halResource.$source._links[linkName] = link;
      }
    } else if ('href' in val) {
      halResource.$source._links[linkName] = {href: val.href};
    }

    if (halResource.$embedded && halResource.$embedded[linkName]) {
      halResource.$embedded[linkName] = val;
      halResource.$source._embedded[linkName] = _.get(val, '$source', val);
    }

    return val;
  }
}

function halResourceService(...args:any[]) {
  [$q, lazy, halLink, halResourceFactory, CacheService] = args;
  return HalResource;
}

halResourceService.$inject = [
  '$q',
  'lazy',
  'HalLink',
  'halResourceFactory',
  'CacheService'
];

opApiModule.factory('HalResource', halResourceService);
