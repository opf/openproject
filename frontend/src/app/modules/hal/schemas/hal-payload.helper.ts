//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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

import { HalResource } from 'core-app/modules/hal/resources/hal-resource';
import { SchemaResource } from 'core-app/modules/hal/resources/schema-resource';

export class HalPayloadHelper {

  /**
   * Extract payload from the given request with schema.
   * This will ensure we will only write writable attributes and so on.
   *
   * @param resource
   * @param schema
   */
  static extractPayload<T extends HalResource = HalResource>(resource:T|Object|null, schema:SchemaResource|null = null):Object {
    if (resource instanceof HalResource && schema) {
      return this.extractPayloadFromSchema(resource, schema);
    } else if (resource && !(resource instanceof HalResource)) {
      return resource;
    } else {
      return {};
    }
  }

  /**
   * Extract writable payload from a HAL resource class to be used for API calls.
   *
   * The schema contains writable information about attributes, which is what this method
   * iterates in order to build the HAL-compatible object.
   *
   * @param resource A HalResource to extract payload from
   * @param schema The associated schema to determine writable state of attributes
   */
  static extractPayloadFromSchema<T extends HalResource = HalResource>(resource:T, schema:SchemaResource) {
    const payload:any = {
      '_links': {}
    };

    const nonLinkProperties = [];

    for (const key in schema) {
      if (schema.hasOwnProperty(key) && schema[key] && schema[key].writable) {
        if (resource.$links[key]) {
          if (Array.isArray(resource[key])) {
            payload['_links'][key] = _.map(resource[key], element => {
              return { href: (element as HalResource).$href };
            });
          } else {
            payload['_links'][key] = {
              href: (resource[key] && resource[key].$href)
            };
          }
        } else {
          nonLinkProperties.push(key);
        }
      }
    }

    _.each(nonLinkProperties, property => {
      if (resource.hasOwnProperty(property) || resource[property]) {
        if (Array.isArray(resource[property])) {
          payload[property] = _.map(resource[property], (element:any) => {
            if (element instanceof HalResource) {
              return this.extractPayloadFromSchema(element, element.currentSchema || element.schema);
            } else {
              return element;
            }
          });
        } else {
          payload[property] = resource[property];
        }
      }
    });

    return payload;
  }
}
