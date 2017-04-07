//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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

import {FormResource} from '../hal-resources/form-resource.service';
import {SchemaResource} from '../hal-resources/schema-resource.service';
import {HalResource} from '../hal-resources/hal-resource.service';
import {opApiModule} from '../../../../angular-modules';

export class PayloadDmService {
  public extract(resource:HalResource, schema:SchemaResource) {
    let payload:any = {
      '_links': {}
    }

    var nonLinkProperties = [];

    for(var key in schema) {
      if (schema.hasOwnProperty(key) && schema[key].writable) {
        if (resource.$links[key]) {
          if (Array.isArray(resource[key])) {
            payload['_links'][key] = _.map(resource[key], element => {
              return { href: (element as HalResource).$href }
            });
          } else {
            payload['_links'][key] = {
              href: (resource[key] && resource[key].$href)
            }
          };
        } else {
          nonLinkProperties.push(key);
        }
      }
    }

    _.each(nonLinkProperties, property => {
      if (resource.hasOwnProperty(property)) {
        if (Array.isArray(resource[property])) {
          payload[property] = _.map(resource[property], (element:any) => {
            if (element instanceof HalResource) {
              return this.extract(element, element.currentSchema || element.schema)
            } else {
              return element;
            }
          });
        } else {
          payload[property] = resource[property];
        }
      }
    });

    return payload;
  }
}

opApiModule.service('PayloadDm', PayloadDmService);
