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

import {opApiModule} from '../../../../angular-modules';
import {HalLink, HalLinkInterface} from '../hal-link/hal-link.service';
import ObservableArray = require('observable-array');

var $q:ng.IQService;
var lazy;
var halResourceTypesStorage:any;

export class HalResource {
  public static _type:string;

  public static create(element) {
    if (!(element._embedded || element._links)) {
      return element;
    }

    const resourceClass = halResourceTypesStorage.getResourceClassOfType(element._type);
    return new resourceClass(element);
  }

  protected static getEmptyResource():any {
    return {_links: {self: {href: null}}};
  }

  public $links:any = {};
  public $embedded:any = {};
  public $self:ng.IPromise<HalResource>;

  private _name:string;

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

  public get href():string {
    return this.$link.href;
  }

  constructor(public $source:any = HalResource.getEmptyResource(),
              public $loaded:boolean = true) {
    this.$source = $source._plain || $source;

    if (!this.$source._links) {
      this.$source._links = {};
    }

    if (!this.$source._links.self) {
      this.$source._links.self = new HalLink();
    }

    this.setupLinks();
    this.setupEmbedded();
    this.proxyProperties();
    this.setLinksAsProperties();
    this.setEmbeddedAsProperties();
  }

  //protected setSource

  public $load() {
    if (this.$loaded) {
      return $q.when(this);
    }

    if (!this.$loaded && this.$self) {
      return this.$self;
    }

    this.$self = this.$links.self().then(resource => {
      this.$loaded = true;
      angular.extend(this, resource);
      return this;
    });

    return this.$self;
  }

  public $plain() {
    return angular.copy(this.$source);
  }

  protected createLinkedResource(linkName, link) {
    var resource = HalResource.getEmptyResource();
    resource._links.self = link;

    const resourceClass = halResourceTypesStorage
      .getResourceClassOfAttribute(this.constructor._type, linkName);

    return new resourceClass(resource, false);
  }

  private proxyProperties() {
    var source = this.$source.restangularized ? this.$source.plain() : this.$source;

    _.without(Object.keys(source), '_links', '_embedded').forEach(property => {
      Object.defineProperty(this, property, {
        get() {
          return this.$source[property];
        },

        set(value) {
          this.$source[property] = value;
        },

        enumerable: true
      });
    });
  }

  private setLinksAsProperties() {
    _.without(Object.keys(this.$links), 'self').forEach(linkName => {
      lazy(this, linkName,
        () => {
          const link:any = this.$links[linkName].$link || this.$links[linkName];

          if (Array.isArray(link)) {
            var items = link.map(item => this.createLinkedResource(linkName, item.$link));
            var property:Array = new ObservableArray(...items).on('change', () => {
              property.forEach(item => {
                if (!item.$link) {
                  property.splice(property.indexOf(item), 1);
                }
              });

              this.$source._links[linkName] = property.map(item => item.$link);
            });

            return property;
          }

          if (link.href) {
            if (link.method !== 'get') {
              return HalLink.asFunc(link);
            }

            return this.createLinkedResource(linkName, link);
          }
        },

        val => this.setter(val, linkName)
      );
    });
  }

  private setEmbeddedAsProperties() {
    Object.keys(this.$embedded).forEach(name => {
      lazy(this, name, () => this.$embedded[name], val => this.setter(val, name));
    });
  }

  private setupProperty(name:string, callback:(element:any) => any) {
    const instanceName = '$' + name;
    const sourceName = '_' + name;
    const sourceObj = this.$source[sourceName];

    if (angular.isObject(sourceObj)) {
      Object.keys(sourceObj).forEach(propName => {
        lazy(this[instanceName], propName, () => callback(sourceObj[propName]));
      });
    }
  }

  private setupLinks() {
    this.setupProperty('links',
      link => Array.isArray(link) ? link.map(HalLink.asFunc) : HalLink.asFunc(link));
  }

  private setupEmbedded() {
    this.setupProperty('embedded', element => {
      angular.forEach(element, (child:any, name:string) => {
        if (child) {
          lazy(element, name, () => HalResource.create(child));
        }
      });

      if (Array.isArray(element)) {
        return element.map(HalResource.create);
      }

      return HalResource.create(element);
    });
  }

  private setter(val, linkName) {
    if (val && val.$link) {
      const link = val.$link;

      if (link.href && link.method === 'get') {
        this.$source._links[linkName] = link;
      }

      return val;
    }
  }
}

function halResourceService() {
  [$q, lazy, HalLink, halResourceTypesStorage] = arguments;
  return HalResource;
}

halResourceService.$inject = [
  '$q',
  'lazy',
  'HalLink',
  'halResourceTypesStorage'
];

opApiModule.factory('HalResource', halResourceService);
