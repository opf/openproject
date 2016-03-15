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

const lazy = (obj:any, property:string, callback:Function, setter:boolean = false) => {
  let value;
  let config = {
    get() {
      if (!value) {
        value = callback();
      }
      return value;
    },
    set: void 0,
  };

  if (setter) {
    config.set = val => value = val;
  }

  Object.defineProperty(obj, property, config);
};

function halResource(halTransform, HalLink, $q) {
  return class HalResource {
    protected static fromLink(link) {
      return new HalResource({_links: {self: link}}, false);
    }

    public $isHal:boolean = true;

    private _name:string;
    private _$links:any;
    private _$embedded:any;

    public get name():string {
      return this._name || this.$links.self.$link.title || '';
    }

    public set name(name:string) {
      this._name = name;
    }

    public get href():string|void {
      // Set .href to the self link href
      // This is a workaround for tracking by link id's
      // since, e.g., assignee's ID is not available.
      if (this.$links.self) {
        return this.$links.self.$link.href;
      }
    }

    public get $links() {
      this._$links = this._$links || this.transformLinks();
      return this._$links;
    }

    public get $embedded() {
      this._$embedded = this._$embedded || this.transformEmbedded();
      return this._$embedded;
    }

    constructor(public $source, public $loaded = true) {
      this.$source = $source._plain || angular.copy($source);

      this.proxyProperties();

      angular.forEach(this.$links, (link, name:string) => {
        if (Array.isArray(link)) {
          this[name] = link.map(HalResource.fromLink);
          return;
        }

        link = link.$link;

        if (link.href && link.method == 'get' && name !== 'self') {
          this[name] =  HalResource.fromLink(link);
        }
        else if (link.method !== 'get') {
          this[name] = link.$toFunc();
        }
      });

      angular.forEach(this.$embedded, (resource, name) => {
        this[name] = resource;
      });
    }

    public $load() {
      if (!this.$loaded) {
        return this.$links.self().then(resource => {
          this.$loaded = true;

          angular.extend(this, resource);
          return this;
        });
      }

      return $q.when(this);
    }

    public $plain() {
      const element:any = angular.copy(this);
      const linked :string[] = Object.keys(this.$links);
      element._links = {};

      linked.forEach(linkName => {
        if (this[linkName] && element[linkName].$links && !angular.isFunction(this[linkName])) {
          element._links[linkName] = element[linkName].$links.self.$link;
        }

        delete element[linkName];
      });

      return element;
    }

    private transformLinks() {
      return this.transformHalProperty('_links', link => {
        if (Array.isArray(link)) {
          return link.map(HalLink.asFunc);
        }

        return HalLink.asFunc(link);
      });
    }

    private transformEmbedded() {
      return this.transformHalProperty('_embedded', element => {
        angular.forEach(element, (child, name) => {
          if (child) element[name] = halTransform(child);
        });

        if (Array.isArray(element)) {
          element.forEach((elem, i) => element[i] = halTransform(elem));
        }

        return halTransform(element);
      });
    }

    private transformHalProperty(propertyName:string, callback:(element:any) => any) {
      var properties = angular.copy(this.$source[propertyName]);

      angular.forEach(properties, (property, name:string) => {
        lazy(properties, name, () => callback(property));
      });

      return properties || {};
    }

    private proxyProperties() {
      _.without(Object.keys(this.$source), '_links', '_embedded').forEach(property => {
        Object.defineProperty(this, property, {
          get() {
            return this.$source[property];
          },
          set(value) {
            this.$source[property] = value;
          }
        });
      });
    }
  }
}

angular
  .module('openproject.api')
  .factory('HalResource', halResource);
