import { HalResource } from 'core-app/modules/hal/resources/hal-resource';
import { OpenprojectHalModuleHelpers } from 'core-app/modules/hal/helpers/lazy-accessor';
import { HalResourceService } from 'core-app/modules/hal/services/hal-resource.service';
import { HalLink } from 'core-app/modules/hal/hal-link/hal-link';

import * as ObservableArray from 'observable-array';

interface HalSource {
  _links:any;
  _embedded:any;
  _type?:string;
  type?:any;
}

export function cloneHalResourceCollection<T extends HalResource>(values:T[]|undefined):T[] {
  if (_.isNil(values)) {
    return [];
  } else {
    return values.map(v => v.$copy<T>());
  }
}

export function cloneHalResource<T extends HalResource>(value:T|undefined):T|undefined {
  if (_.isNil(value)) {
    return value;
  } else {
    return value.$copy<T>();
  }
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
    if (_.isNil(value)) {
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
        configurable: true
      });
    });
  }

  function setLinksAsProperties() {
    halResource.$linkableKeys().forEach((linkName:string) => {
      OpenprojectHalModuleHelpers.lazy(halResource, linkName,
        () => {
          const link:any = halResource.$links[linkName].$link || halResource.$links[linkName];

          if (Array.isArray(link)) {
            var items = link.map(item => halResourceService.createLinkedResource(halResource,
              linkName,
              item.$link));
            var property:HalResource[] = new ObservableArray(...items).on('change', () => {
              property.forEach(item => {
                if (!item.$link) {
                  property.splice(property.indexOf(item), 1);
                }
              });

              halResource.$source._links[linkName] = property.map(item => item.$link);
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
        (val:any) => setter(val, linkName)
      );
    });
  }

  function setEmbeddedAsProperties() {
    if (!halResource.$source._embedded) {
      return;
    }

    Object.keys(halResource.$source._embedded).forEach(name => {
      OpenprojectHalModuleHelpers.lazy(halResource,
        name,
        () => halResource.$embedded[name],
        (val:any) => setter(val, name));
    });
  }

  function setupProperty(name:string, callback:(element:any) => any) {
    const instanceName = '$' + name;
    const sourceName = '_' + name;
    const sourceObj:any = halResource.$source[sourceName];

    if (_.isObject(sourceObj)) {
      Object.keys(sourceObj).forEach(propName => {
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
          return link.map(l => HalLink.fromObject(halResourceService, l).$callable());
        } else {
          return HalLink.fromObject(halResourceService, link).$callable();
        }
      });
  }

  function setupEmbedded() {
    setupProperty('embedded', (element:any) => {

      if (Array.isArray(element)) {
        return element.map((source) => asHalResource(source, true));
      }

      if (_.isObject(element)) {
        _.each(element, (child:any, name:string) => {
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
      halResource.$source._links[linkName] = (val as HalResource[]).map((el:any) => {
        return { href: el.href };
      });
    } else if (val.hasOwnProperty('$link')) {
      const link = (val as HalResource).$link;

      if (link.href) {
        halResource.$source._links[linkName] = link;
      }
    } else if ('href' in val) {
      halResource.$source._links[linkName] = { href: val.href };
    }

    if (halResource.$embedded && halResource.$embedded[linkName]) {
      halResource.$embedded[linkName] = val;

      if (isArray) {
        halResource.$source._embedded[linkName] = (val as HalResource[]).map(el => el.$source);
      } else {
        halResource.$source._embedded[linkName] = _.get(val, '$source', val);
      }
    }

    return val;
  }
}
