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

//TODO: Implement tests
function halTransformedElementService(Restangular:restangular.IService) {
  return class HalTransformedElement {
    constructor(protected element) {
      return this.transform();
    }

    protected transform() {
      if (!this.element._links && !this.element._embedded) return this.element;

      /**
       * The properties added by the transformation should not be enumerable, so that
       * Restangular's `.plain()` returns only the relevant properties.
       */
      Object.defineProperties(this.element, {
        /**
         *
         */
        links: {value: this.transformLinks()},

        /**
         *
         */
        embedded: {value: this.transformEmbedded()},

        /**
         * Gets a linked resource and sets its plain value as the element's property.
         * @method
         */
        linkedProp: {
          value: (propertyName:string) => {
            //TODO: return null or empty promise if link does not exist - or throw an exception
            return !!this.element.links[propertyName] && this.element.links[propertyName]().then(value => {
                return this.element[propertyName] = value.plain();
              });
          }
        },

        /**
         * Set linked and embedded plain resource results as properties of the element.
         * @method
         */
        //TODO: maybe return an array of promises with $q.all
        linkedProps: {
          value: (propertyNames:string[]) => {
            propertyNames.forEach(this.element.linkedProp);
          }
        }
      });

      return this.element;
    }

    /**
     * Transform links
     *
     * Links are methods that return a promise.
     * Collections can be requested by `link[linkName].all()`.
     */
    protected transformLinks() {
      return this.transformHalProperty('_links', (links, link, linkName) => {
        var method = (method:string, multiplier?:string = 'oneUrl') => {
          return (...params) => {
            if (method === 'post') params.unshift('');
            return this.element[multiplier](linkName, link.href)[method].apply(this.element, params);
          }
        };

        if (!link.method) {
          links[linkName] = method('get');
          links[linkName].all = method('getList', 'allUrl');
        }
        else {
          links[linkName] = method(link.method);
        }

        // Add a _source property so the information of the source is accessible
        Object.defineProperty(links[linkName], '_source', {value: link});
      });
    }

    /**
     * Transform embedded properties to actual HAL resources.
     */
    //TODO: make restangularizeElement work correctly
    protected transformEmbedded() {
      return this.transformHalProperty('_embedded', (all, embedded, name) => {
        angular.forEach(embedded, element => {
          if (element && (element._links || element._embedded)) {
            this.restangularize(element);
          }
        });

        all[name] = this.restangularize(embedded);
      })
    }

    protected restangularize(element) {
      return new HalTransformedElement(Restangular.restangularizeElement(null, element, ''));
    }

    /**
     *
     * @param name
     * @param callback
     * @returns {{}}
     */
    protected transformHalProperty(name:string, callback:Function) {
      var properties = {};
      var _properties = this.element[name];
      delete this.element[name];

      angular.forEach(_properties, (property, name) => {
        callback(properties, property, name);
      });

      return properties;
    }
  };
}

angular
  .module('openproject.api')
  .factory('HalTransformedElement', halTransformedElementService);
