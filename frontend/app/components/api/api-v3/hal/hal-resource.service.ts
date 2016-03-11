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

function halResource(halTransform, HalLink, $q) {
  return class HalResource {
    protected static fromLink(link) {
      return new HalResource({_links: {self: link}}, false);
    }

    public $links;
    public $embedded;
    public $isHal:boolean = true;
    public href:string;

    private _name:string;
    private source:any;

    public get name():string {
      return this._name || this.$links.self.$link.title || '';
    }

    public set name(name:string) {
      this._name = name;
    }

    constructor(protected $source, public $loaded = true) {
      this.source = angular.copy($source.restangularized ? $source.$plain : $source);

      this.$links = this.transformLinks();
      this.$embedded = this.transformEmbedded();

      // Set .href to the self link href
      // This is a workaround for tracking by link id's
      // since, e.g., assignee's ID is not available.
      if (this.$links && this.$links.self) {
        this.href = this.$links.self.$link.href;
      }

      angular.extend(this, this.source);

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
      const element = <any> angular.copy(this);
      const linked = Object.keys(this.$links);
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
      return this.transformHalProperty('_links', (link) => {
        if (Array.isArray(link)) {
          return link.map(HalLink.asFunc);
        }

        return HalLink.asFunc(link);
      });
    }

    private transformEmbedded() {
      return this.transformHalProperty('_embedded', (element) => {
        angular.forEach(element, (child, name) => {
          if (child) element[name] = halTransform(child);
        });

        if (Array.isArray(element)) {
          element.forEach((elem, i) => element[i] = halTransform(elem));
        }

        return halTransform(element);
      });
    }

    private transformHalProperty(propertyName:string, callback:(element) => any) {
      var properties = this.source[propertyName];
      delete this.source[propertyName];

      angular.forEach(properties, (property, name) => {
        properties[name] = callback(property);
      });

      return properties;
    }
  }
}

angular
  .module('openproject.api')
  .factory('HalResource', halResource);
