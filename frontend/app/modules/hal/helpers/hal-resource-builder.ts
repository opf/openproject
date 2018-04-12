import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {OpenprojectHalModuleHelpers} from 'core-app/modules/hal/helpers/lazy-accessor';
import {Injector} from '@angular/core';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {HalLink} from 'core-app/modules/hal/hal-link/hal-link';

const ObservableArray:any = require('observable-array');

export class HalResourceBuilder<T extends HalResource> {

  private constructor(readonly halResourceService:HalResourceService,
                      private halResource:T) {
    this.setSource();
    this.setupLinks();
    this.setupEmbedded();
    this.proxyProperties();
    this.setLinksAsProperties();
    this.setEmbeddedAsProperties();
  }

  /**
   * Initialize the lazy embedded and link properties from the HalResource source.
   *
   * @param {Injector} injector
   * @param {T} halResource
   * @returns {T} The same halResource with properties mapped to their sources.
   */
  public static initialize<T extends HalResource>(halResourceService:HalResourceService, halResource:T):T {
    const builder = new HalResourceBuilder<T>(halResourceService, halResource);
    return builder.halResource;
  }

  private setSource() {
    if (!this.halResource.$source._links) {
      this.halResource.$source._links = {};
    }

    if (!this.halResource.$source._links.self) {
      this.halResource.$source._links.self = { href: null };
    }
  }

  private proxyProperties() {
    this.halResource.$embeddableKeys().forEach((property:any) => {
      Object.defineProperty(this.halResource, property, {
        get() {
          return this.halResource.$source[property];
        },

        set(value) {
          this.halResource.$source[property] = value;
        },

        enumerable: true,
        configurable: true
      });
    });
  }

  private setLinksAsProperties() {
    this.halResource.$linkableKeys().forEach((linkName:string) => {
      OpenprojectHalModuleHelpers.lazy(this.halResource, linkName,
        () => {
          const link:any = this.halResource.$links[linkName].$link || this.halResource.$links[linkName];

          if (Array.isArray(link)) {
            var items = link.map(item => this.halResourceService.createLinkedResource(linkName,
              item.$link));
            var property:HalResource[] = new ObservableArray(...items).on('change', () => {
              property.forEach(item => {
                if (!item.$link) {
                  property.splice(property.indexOf(item), 1);
                }
              });

              this.halResource.$source._links[linkName] = property.map(item => item.$link);
            });

            return property;
          }

          if (link.href) {
            if (link.method !== 'get') {
              return HalLink.fromObject(this.halResourceService, link).$callable();
            }

            return this.halResource.createLinkedResource(linkName, link);
          }

          return null;
        },
        (val:any) => this.setter(val, linkName)
      );
    });
  }

  private setEmbeddedAsProperties() {
    if (!this.halResource.$source._embedded) {
      return;
    }

    Object.keys(this.halResource.$source._embedded).forEach(name => {
      OpenprojectHalModuleHelpers.lazy(this.halResource,
        name,
        () => this.halResource.$embedded[name],
        (val:any) => this.setter(val, name));
    });
  }

  private setupProperty(name:string, callback:(element:any) => any) {
    const instanceName = '$' + name;
    const sourceName = '_' + name;
    const sourceObj = this.halResource.$source[sourceName];

    if (angular.isObject(sourceObj)) {
      Object.keys(sourceObj).forEach(propName => {
        OpenprojectHalModuleHelpers.lazy((this.halResource)[instanceName],
          propName,
          () => callback(sourceObj[propName]));
      });
    }
  }

  private setupLinks() {
    this.setupProperty('links',
      (link) => {
        if (Array.isArray(link)) {
          return link.map(l => HalLink.fromObject(this.halResourceService, l).$callable());
        } else {
          return HalLink.fromObject(this.halResourceService, link).$callable();
        }
      });
  }

  private setupEmbedded() {
    this.setupProperty('embedded', element => {
      angular.forEach(element, (child:any, name:string) => {
        if (child && (child._embedded || child._links)) {
          OpenprojectHalModuleHelpers.lazy(element,
            name,
            () => this.halResource.createHalResource(child));
        }
      });

      if (Array.isArray(element)) {
        return element.map((source) => this.halResourceService.createHalResource(source,
          true));
      }

      return this.halResourceService.createHalResource(element);
    });
  }

  private setter(val:HalResource|{ href?:string }, linkName:string) {
    if (!val) {
      this.halResource.$source._links[linkName] = { href: null };
    } else if (_.isArray(val)) {
      this.halResource.$source._links[linkName] = val.map((el:any) => {
        return { href: el.href }
      });
    } else if (val.hasOwnProperty('$link')) {
      const link = (val as HalResource).$link;

      if (link.href) {
        this.halResource.$source._links[linkName] = link;
      }
    } else if ('href' in val) {
      this.halResource.$source._links[linkName] = { href: val.href };
    }

    if (this.halResource.$embedded && this.halResource.$embedded[linkName]) {
      this.halResource.$embedded[linkName] = val;
      this.halResource.$source._embedded[linkName] = _.get(val, '$source', val);
    }

    return val;
  }
}
