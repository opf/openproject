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

function halTransformedElementService(Restangular:restangular.IService, $q:ng.IQService) {
  return class HalTransformedElement {
    constructor(protected element) {
      return this.transform();
    }

    protected transform() {
      if (!this.element._links && !this.element._embedded) return this.element;

      const propertiesSet = [];

      angular.extend(this.element, {
        /**
         * Linked resources of the element.
         */
        $links: this.transformLinks(),

        /**
         * Embedded resources of the element
         */
        $embedded: this.transformEmbedded(),

        /**
         * Write the linked property's value back to the original _links attribute.
         * This is useful, if you want to save the resource.
         * @method
         */
        //TODO: Maybe delete the linked property, as it has no use.
        $data: () => {
          var plain = this.element.plain();
          plain._links = {};


          angular.forEach(this.element.$links, (link, name) => {
            var property = this.element[name];
            var source = link._source;

            if (propertiesSet.indexOf(name) !== -1) {
              if (property._links) {
                property = new HalTransformedElement(property);
              }

              if (property.$links.self) {
                source = property.$links.self._source;
              }
            }

            plain._links[name] = source;
          });

          return plain;
        },

        /**
         * Indicate whether the element has been transformed.
         * @boolean
         */
        $halTransformed: true
      });

      //TODO: Embedded properties should also be added
      angular.forEach(this.element.$links, (link, linkName) => {
        const property = {};
        angular.extend(property, link);
        this.element[linkName] = property;
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
        const method = (method:string, multiplier:string) => {
          return (...params) => {
            if (!link.href) {
              return $q.when({});
            }

            if (method === 'post') {
              params.unshift('');
            }

            return Restangular[multiplier](linkName, link.href)[method]
              .apply(this.element, params)
              .then((value:op.ApiResult) => {
                if (value) {
                  if (value.restangularized) {
                    value = value.plain();
                  }

                  angular.extend(this.element[linkName], new HalTransformedElement(value));
                }

                return value;
              });
          }
        };

        if (!link.method) {
          links[linkName] = method('get', 'oneUrl');
          links[linkName].list = method('getList', 'allUrl');
        }
        else {
          links[linkName] = method(link.method, 'oneUrl');
        }

        angular.extend(links[linkName], link);
      });
    }

    /**
     * Transform embedded properties and their children to actual HAL resources,
     * if they have links or embedded resources.
     */
    protected transformEmbedded() {
      return this.transformHalProperty('_embedded', (embedded, element, name) => {
        angular.forEach(element, child => child && new HalTransformedElement(element));
        embedded[name] = new HalTransformedElement(element);
      });
    }

    /**
     *
     * @param propertyName
     * @param callback
     * @returns {{}}
     */
    protected transformHalProperty(propertyName:string, callback:(props, prop, name) => any) {
      var properties = this.element[propertyName];

      delete this.element[propertyName];

      angular.forEach(properties, (property, name) => {
        callback(properties, property, name);
      });

      return properties;
    }
  };
}

angular
  .module('openproject.api')
  .factory('HalTransformedElement', halTransformedElementService);
