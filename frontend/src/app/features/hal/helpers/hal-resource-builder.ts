//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import ObservableArray from 'observable-array';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { HalLink } from 'core-app/features/hal/hal-link/hal-link';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { OpenprojectHalModuleHelpers } from 'core-app/features/hal/helpers/lazy-accessor';
import { HalSource } from 'core-app/features/hal/interfaces';

export function cloneHalResourceCollection<T extends HalResource>(values:T[]|undefined):T[] {
  if (values == null) {
    return [];
  }
  return values.map((v) => v.$copy<T>());
}

export function cloneHalResource<T extends HalResource>(value:T|undefined):T|undefined {
  if (value == null) {
    return value;
  }
  return value.$copy<T>();
}

export function initializeHalProperties<T extends HalResource>(halResourceService:HalResourceService, halResource:T) {
  setSource();
  setupLinks();
  setupEmbedded();
  proxyProperties();
  setLinksAsProperties();
  setEmbeddedAsProperties();

  function setSource() {
    if (!halResource.$source._links) {
      halResource.$source._links = {};
    }

    if (!halResource.$source._links.self) {
      halResource.$source._links.self = { href: null };
    }
  }

  function asHalResource(value?:HalSource, loaded = true):HalResource|HalSource|undefined|null {
    if (value == null) {
      return value;
    }

    if (value._links || value._embedded || value._type) {
      return halResourceService.createHalResource(value, loaded);
    }

    return value;
  }

  function proxyProperties() {
    halResource.$embeddableKeys().forEach((property:any) => {
      Object.defineProperty(halResource, property, {
        get() {
          const value = halResource.$source[property];
          return asHalResource(value, true);
        },

        set(value) {
          halResource.$source[property] = value;
        },

        enumerable: true,
        configurable: true,
      });
    });
  }

  function setLinksAsProperties() {
    halResource.$linkableKeys().forEach((linkName:string) => {
      OpenprojectHalModuleHelpers.lazy(halResource, linkName,
        () => {
          const link:any = halResource.$links[linkName].$link || halResource.$links[linkName];

          if (Array.isArray(link)) {
            const items = link.map((item) => halResourceService.createLinkedResource(halResource,
              linkName,
              item.$link));
            var property:HalResource[] = new ObservableArray(...items).on('change', () => {
              property.forEach((item) => {
                if (!item.$link) {
                  property.splice(property.indexOf(item), 1);
                }
              });

              halResource.$source._links[linkName] = property.map((item) => item.$link);
            });

            return property;
          }

          if (link.href) {
            if (link.method !== 'get') {
              return HalLink.fromObject(halResourceService, link).$callable();
            }

            return halResourceService.createLinkedResource(halResource, linkName, link);
          }

          return null;
        },
        (val:any) => setter(val, linkName));
    });
  }

  function setEmbeddedAsProperties() {
    if (!halResource.$source._embedded) {
      return;
    }

    Object.keys(halResource.$source._embedded).forEach((name) => {
      OpenprojectHalModuleHelpers.lazy(halResource,
        name,
        () => halResource.$embedded[name],
        (val:any) => setter(val, name));
    });
  }

  function setupProperty(name:string, callback:(element:any) => any) {
    const instanceName = `$${name}`;
    const sourceName = `_${name}`;
    const sourceObj:any = halResource.$source[sourceName];

    if (typeof sourceObj === 'object' && sourceObj !== null) {
      Object.keys(sourceObj).forEach((propName) => {
        OpenprojectHalModuleHelpers.lazy((halResource)[instanceName],
          propName,
          () => callback((sourceObj as any)[propName]));
      });
    }
  }

  function setupLinks() {
    setupProperty('links',
      (link) => {
        if (Array.isArray(link)) {
          return link.map((l) => HalLink.fromObject(halResourceService, l).$callable());
        }
        return HalLink.fromObject(halResourceService, link).$callable();
      });
  }

  function setupEmbedded() {
    setupProperty('embedded', (element:any) => {
      if (Array.isArray(element)) {
        return element.map((source) => asHalResource(source, true));
      }

      if (typeof element === 'object' && element !== null) {
        Object.entries(element as Record<string, HalSource>).forEach(([name, child]) => {
          if (child && (child._embedded || child._links)) {
            OpenprojectHalModuleHelpers.lazy(element as any,
              name,
              () => asHalResource(child, true));
          }
        });
      }

      return asHalResource(element, true);
    });
  }

  function setter(val:HalResource[]|HalResource|{ href?:string }, linkName:string) {
    const isArray = Array.isArray(val);

    if (!val) {
      halResource.$source._links[linkName] = { href: null };
    } else if (isArray) {
      halResource.$source._links[linkName] = (val).map((el:any) => ({ href: el.href }));
    } else if (val.hasOwnProperty('$link')) {
      const link = (val as HalResource).$link;

      if (link.href) {
        halResource.$source._links[linkName] = link;
      }
    } else if ('href' in val) {
      halResource.$source._links[linkName] = { href: val.href };
    }

    if (halResource.$embedded?.[linkName]) {
      halResource.$embedded[linkName] = val;

      if (isArray) {
        halResource.$source._embedded[linkName] = (val).map((el) => el.$source);
      } else {
        const source:unknown = (val as HalResource | undefined)?.$source;
        (halResource.$source as { _embedded:Record<string, unknown> })._embedded[linkName] = source === undefined ? val : source;
      }
    }

    return val;
  }
}
