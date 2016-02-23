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

      const propertiesSet = [];
      /**
       * The properties added by the transformation should not be enumerable, so that
       * Restangular's `.plain()` returns only the relevant properties.
       */
      Object.defineProperties(this.element, {
        /**
         * Linked resources of the element.
         */
        links: {value: this.transformLinks()},

        /**
         * Embedded resources of the element
         */
        embedded: {value: this.transformEmbedded()},

        /**
         * Gets a linked or embedded resource and sets its plain value as a property of the
         * element.
         * Request the linked resource, if it's not embedded.
         * @method
         */
        //TODO: Add embedded resource handling (see description).
        //TODO: Always return a promise.
        setProperty: {
          value: (propertyName:string) => {
            return !!this.element.links[propertyName] && this.element.links[propertyName]().then(value => {
                propertiesSet.push(propertyName);
                return this.element[propertyName] = value;
              });
          }
        },

        /**
         * Set linked or embedded resources as properties of the element.
         * @method
         */
        //TODO: Return a promise based on $q.all
        setProperties: {
          value: (propertyNames:string[]) => {
            propertyNames.forEach(this.element.setProperty);
          }
        },

        /**
         * Write the linked property's value back to the original _links attribute.
         * This is useful, if you want to save the resource.
         * @method
         */
        //TODO: Handle _embedded properties (it it makes any sense - probably not).
        //TODO: Maybe delete the linked property, as it has no use.
        data: {
          value: () => {
            var plain = this.element.plain();
            plain._links = {};


            angular.forEach(this.element.links, (link, name) => {
              var property = this.element[name];
              var source = link._source;

              if (propertiesSet.indexOf(name) !== -1) {
                if (property._links) {
                  property = new HalTransformedElement(property);
                }

                if (property.links.self) {
                  source = property.links.self._source;
                }
              }

              plain._links[name] = source;
            });

            return plain;
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
    //TODO: Implement handling for link arrays (see schema.priority._links.allowedValues)
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
      });
    }

    /**
     * Transform embedded properties and their children to actual HAL resources,
     * if they have links or embedded resources.
     */
    protected transformEmbedded() {
      return this.transformHalProperty('_embedded', (embedded, element, name) => {
        angular.forEach(element, child => child && this.restangularize(child));
        embedded[name] = new HalTransformedElement(element);
      });
    }

    protected restangularize(element) {
      if (!(element._links || element._embedded)) {
        return element;
      }

      return new HalTransformedElement(Restangular.restangularizeElement(null, element, ''));
    }

    /**
     *
     * @param propertyName
     * @param callback
     * @returns {{}}
     */
    protected transformHalProperty(propertyName:string, callback:(props, prop, name) => any) {
      var properties = {};
      var _properties = this.element[propertyName];

      delete this.element[propertyName];

      angular.forEach(_properties, (property, name) => {
        callback(properties, property, name);
      });

      // Add a _source property so the information of the source is accessible
      angular.forEach(properties, (property, name) => {
        if (_properties[name]) {
          Object.defineProperty(
            properties[name], '_source', {value: angular.copy(_properties[name])});
        }
      });

      return properties;
    }
  };
}

angular
  .module('openproject.api')
  .factory('HalTransformedElement', halTransformedElementService);
