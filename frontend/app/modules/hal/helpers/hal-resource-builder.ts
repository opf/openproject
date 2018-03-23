import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {OpenprojectHalModuleHelpers} from 'core-app/modules/hal/helpers/lazy-accessor';
import {HalLinkService} from 'core-app/modules/hal/hal-link/hal-link.service';
import {HalResourceFactoryService} from 'core-app/modules/hal/services/hal-resource-factory.service';

const ObservableArray:any = require('observable-array');

export function initializeHalResource(halResource:HalResource,
                                   halResourceFactory:HalResourceFactoryService,
                                   halLinkService:HalLinkService) {
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
      halResource.$source._links.self = {href: null};
    }
  }

  function proxyProperties() {
    halResource.$embeddableKeys().forEach((property:any) => {
      Object.defineProperty(halResource, property, {
        get() {
          return halResource.$source[property];
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
            var items = link.map(item => halResource.createLinkedResource(linkName, item.$link));
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
              return halLinkService.callable(link);
            }

            return halResource.createLinkedResource(linkName, link);
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
    const sourceObj = halResource.$source[sourceName];

    if (angular.isObject(sourceObj)) {
      Object.keys(sourceObj).forEach(propName => {
        OpenprojectHalModuleHelpers.lazy((halResource as any)[instanceName],
          propName,
          () => callback(sourceObj[propName]));
      });
    }
  }

  function setupLinks() {
    setupProperty('links',
      (link) => {
        if (Array.isArray(link)) {
          return link.map(l => halLinkService.callable(l));
        } else {
          return halLinkService.callable(link);
        }
      });
  }

  function setupEmbedded() {
    setupProperty('embedded', element => {
      angular.forEach(element, (child:any, name:string) => {
        if (child && (child._embedded || child._links)) {
          OpenprojectHalModuleHelpers.lazy(element,
            name,
            () => halResourceFactory.createHalResource(child));
        }
      });

      if (Array.isArray(element)) {
        return element.map((source) => halResourceFactory.createHalResource(source,
          true));
      }

      return halResourceFactory.createHalResource(element);
    });
  }

  function setter(val:HalResource|{ href?:string }, linkName:string) {
    if (!val) {
      halResource.$source._links[linkName] = {href: null};
    } else if (_.isArray(val)) {
      halResource.$source._links[linkName] = val.map((el:any) => {
        return {href: el.href}
      });
    } else if (val.hasOwnProperty('$link')) {
      const link = (val as HalResource).$link;

      if (link.href) {
        halResource.$source._links[linkName] = link;
      }
    } else if ('href' in val) {
      halResource.$source._links[linkName] = {href: val.href};
    }

    if (halResource.$embedded && halResource.$embedded[linkName]) {
      halResource.$embedded[linkName] = val;
      halResource.$source._embedded[linkName] = _.get(val, '$source', val);
    }

    return val;
  }
}
