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
import { CallableHalLink, HalLink, HalLinkInterface } from 'core-app/features/hal/hal-link/hal-link';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { OpenprojectHalModuleHelpers } from 'core-app/features/hal/helpers/lazy-accessor';
import { HalSource, HalSourceLink } from 'core-app/features/hal/interfaces';

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

  function sourceLinks():Record<string, HalSourceLink|HalSourceLink[]> {
    return halResource.$source._links;
  }

  function sourceEmbedded():Record<string, unknown>|undefined {
    return halResource.$source._embedded as Record<string, unknown>|undefined;
  }

  function setSource() {
    if (!halResource.$source._links) {
      halResource.$source._links = {};
    }

    if (!halResource.$source._links.self) {
      halResource.$source._links.self = { href: null };
    }
  }

  function asHalResource(value?:HalSource|null, loaded = true):HalResource|HalSource|undefined|null {
    if (value == null) {
      return value;
    }

    if (value._links || value._embedded || value._type) {
      return halResourceService.createHalResource(value, loaded);
    }

    return value;
  }

  function proxyProperties() {
    halResource.$embeddableKeys().forEach((property:string) => {
      Object.defineProperty(halResource, property, {
        get() {
          const value = halResource.$source[property] as HalSource|undefined;
          return asHalResource(value, true);
        },

        set(value:unknown) {
          halResource.$source[property] = value;
        },

        enumerable: true,
        configurable: true,
      });
    });
  }

  function setLinksAsProperties() {
    halResource.$linkableKeys().forEach((linkName:string) => {
      OpenprojectHalModuleHelpers.lazy<unknown>(halResource, linkName,
        () => {
          const entry = halResource.$links[linkName] as CallableHalLink|CallableHalLink[];
          const link = (entry as CallableHalLink).$link || entry;

          if (Array.isArray(link)) {
            const items = link.map((item:CallableHalLink) => halResourceService.createLinkedResource(halResource,
              linkName,
              item.$link));
            const property:HalResource[] = new ObservableArray(...items).on('change', () => {
              property.forEach((item) => {
                if (!item.$link) {
                  property.splice(property.indexOf(item), 1);
                }
              });

              sourceLinks()[linkName] = property.map((item) => item.$link);
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
        (val) => setter(val, linkName));
    });
  }

  function setEmbeddedAsProperties() {
    const embedded = sourceEmbedded();

    if (!embedded) {
      return;
    }

    Object.keys(embedded).forEach((name) => {
      OpenprojectHalModuleHelpers.lazy<unknown>(halResource,
        name,
        () => halResource.$embedded[name],
        (val) => setter(val, name));
    });
  }

  function setupProperty(sourceName:'_links'|'_embedded', target:object, callback:(element:unknown) => unknown) {
    const sourceObj = halResource.$source[sourceName];

    if (typeof sourceObj === 'object' && sourceObj !== null) {
      Object.keys(sourceObj).forEach((propName) => {
        OpenprojectHalModuleHelpers.lazy(target,
          propName,
          () => callback((sourceObj as Record<string, unknown>)[propName]));
      });
    }
  }

  function setupLinks() {
    setupProperty('_links',
      halResource.$links,
      (link) => {
        if (Array.isArray(link)) {
          return (link as HalLinkInterface[]).map((l) => HalLink.fromObject(halResourceService, l).$callable());
        }
        return HalLink.fromObject(halResourceService, link as HalLinkInterface).$callable();
      });
  }

  function setupEmbedded() {
    setupProperty('_embedded', halResource.$embedded, (element) => {
      if (Array.isArray(element)) {
        return (element as HalSource[]).map((source) => asHalResource(source, true));
      }

      if (typeof element === 'object' && element !== null) {
        Object.entries(element as Record<string, HalSource>).forEach(([name, child]) => {
          if (child && (child._embedded || child._links)) {
            OpenprojectHalModuleHelpers.lazy(element,
              name,
              () => asHalResource(child, true));
          }
        });
      }

      return asHalResource(element as HalSource|undefined, true);
    });
  }

  function setter(val:unknown, linkName:string):unknown {
    const isArray = Array.isArray(val);

    if (!val) {
      sourceLinks()[linkName] = { href: null };
    } else if (isArray) {
      sourceLinks()[linkName] = (val as HalResource[]).map((el) => ({ href: el.href }));
    } else if (Object.hasOwn(val, '$link')) {
      const link = (val as HalResource).$link;

      if (link.href) {
        sourceLinks()[linkName] = link;
      }
    } else if ('href' in (val as { href?:string })) {
      sourceLinks()[linkName] = { href: (val as { href?:string }).href };
    }

    if (halResource.$embedded?.[linkName]) {
      halResource.$embedded[linkName] = val;
      const embedded = sourceEmbedded()!;

      if (isArray) {
        embedded[linkName] = (val as HalResource[]).map((el) => el.$source);
      } else {
        const source:unknown = (val as HalResource | undefined)?.$source;
        embedded[linkName] = source === undefined ? val : source;
      }
    }

    return val;
  }
}
