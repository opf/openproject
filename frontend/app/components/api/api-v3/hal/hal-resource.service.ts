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

function halResource(halTransform, HalLink) {
  return class HalResource {
    public $links;
    public $embedded;
    public $halTransformed: boolean = true;

    constructor(protected $source) {
      var source = this.$source.restangularized ? this.$source.plain() : angular.copy(this.$source);
      this.$links = this.transformLinks();
      this.$embedded = this.transformEmbedded();

      delete source._links;
      delete source._embedded;
      angular.extend(this, source);
    }

    public $plain() {
      const element = angular.copy(this);
      const linked = Object.keys(this.$links);
      element._links = {};

      linked.forEach(linkName => {
        element._links[linkName] = this[linkName];

        delete element[linkName];
      });

      return element;
    }

    /**
     * Transform links
     *
     * Links are methods that return a promise.
     * Collections can be requested by `link[linkName].all()`.
     */
    //TODO: Implement handling for link arrays (see schema.priority._links.allowedValues)
    private transformLinks() {
      return this.transformHalProperty('_links', HalLink.fromObject);
    }

    /**
     * Transform embedded properties and their children to actual HAL resources,
     * if they have links or embedded resources.
     */
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

    /**
     *
     * @param propertyName
     * @param callback
     * @returns {{}}
     */
    private transformHalProperty(propertyName:string, callback:(element) => any) {
      var properties = angular.copy(this.$source[propertyName]);

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
