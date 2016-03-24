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

function halResource($q, _, lazy, halTransform, HalLink) {
  return class HalResource {
    protected static fromLink(link) {
      return new HalResource({_links: {self: link}}, false);
    }

    public $isHal:boolean = true;
    public $self: ng.IPromise<HalResource>;

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
      if (this.$links.self) return this.$links.self.$link.href;
    }

    public get $links() {
      return this.setupProperty('links',
        link => Array.isArray(link) ? link.map(HalLink.asFunc) : HalLink.asFunc(link));
    }

    public get $embedded() {
      return this.setupProperty('embedded', element => {
        angular.forEach(element, (child, name:string) => {
          if (child) {
            lazy(element, name, () => halTransform(child));
          }
        });

        if (Array.isArray(element)) {
          return element.map(halTransform);
        }

        return halTransform(element);
      });
    }

    constructor(public $source, public $loaded = true) {
      this.$source = $source._plain || $source;

      this.proxyProperties();
      this.setLinksAsProperties();
      this.setEmbeddedAsProperties();
    }

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

    private proxyProperties() {
      _.without(Object.keys(this.$source), '_links', '_embedded').forEach(property => {
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
            let link = this.$links[linkName].$link || this.$links[linkName];

            if (Array.isArray(link)) {
              return link.map(HalResource.fromLink);
            }

            if (link.href) {
              if (link.method !== 'get') {
                return HalLink.asFunc(link);
              }
              return HalResource.fromLink(link);
            }
          },
          val => {
            if (val && val.$links && val.$links.self) {
              let link = val.$links.self.$link;

              if (link && link.href && link.method === 'get') {
                if (val && val.$isHal) {
                  this.$source._links[linkName] = val.$links.self.$link;
                }

                return val;
              }
            }
          })
      });
    }

    private setEmbeddedAsProperties() {
      Object.keys(this.$embedded).forEach(name => {
        lazy(this, name, () => this.$embedded[name], val => val);
      });
    }

    private setupProperty(name:string, callback:(element:any) => any) {
      let instanceName = '_$' + name;
      let sourceName = '_' + name;
      let sourceObj = this.$source[sourceName];

      if (!this[instanceName] && angular.isObject(sourceObj)) {
        this[instanceName] = {};

        Object.keys(sourceObj).forEach(propName => {
          lazy(this[instanceName], propName, () => callback(sourceObj[propName]));
        });
      }

      return this[instanceName] || {};
    }
  }
}

angular
  .module('openproject.api')
  .factory('HalResource', halResource);
