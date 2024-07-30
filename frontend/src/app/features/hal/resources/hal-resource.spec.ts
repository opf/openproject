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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injector } from '@angular/core';
import { TestBed, waitForAsync } from '@angular/core/testing';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { States } from 'core-app/core/states/states.service';
import { of } from 'rxjs';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { OpenprojectHalModule } from 'core-app/features/hal/openproject-hal.module';
import { HalLink, HalLinkInterface } from 'core-app/features/hal/hal-link/hal-link';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import Spy = jasmine.Spy;

describe('HalResource', () => {
  let halResourceService:HalResourceService;
  let injector:Injector;

  let source:any;
  let resource:HalResource;

  class OtherResource extends HalResource {
  }

  beforeEach(waitForAsync(() => {
    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      imports: [
        OpenprojectHalModule,
        HttpClientTestingModule,
      ],
      providers: [
        HalResourceService,
        States,
        I18nService,
      ],
    })
      .compileComponents()
      .then(() => {
        halResourceService = TestBed.inject(HalResourceService);
        injector = TestBed.inject(Injector);
      });
  }));

  it('should be instantiable using a default object', () => {
    const resource = halResourceService.createHalResource({}, true);
    expect(resource.href).toEqual(null);
  });

  describe('when updating a loaded resource using `$update()`', () => {
    let getStub:jasmine.Spy;

    beforeEach(() => {
      source = {
        _links: {
          self: {
            href: '/api/hello',
          },
        },
      };

      getStub = spyOn(halResourceService, 'request').and.callFake((verb:string, path:string) => {
        if (verb === 'get' && path === '/api/hello') {
          return of(halResourceService.createHalResource(source)) as any;
        }
        return false as any;
      });
    });

    it('should perform a request', () => {
      resource = halResourceService.createHalResource(source, true);
      resource.$update();
      expect(getStub).toHaveBeenCalled();
    });
  });

  describe('when creating a resource using the create factory method', () => {
    describe('when there is no type configuration', () => {
      beforeEach(() => {
        source = { _embedded: {} };
        resource = halResourceService.createHalResource(source, true);
      });

      it('should be an instance of HalResource', () => {
        expect(resource).toEqual(jasmine.any(HalResource));
      });
    });

    describe('when the type is configured', () => {
      beforeEach(() => {
        source = {
          _type: 'Other',
          _links: {
            someResource: {
              href: 'foo',
            },
          },
        };

        halResourceService.registerResource(
          'Other',
          { cls: OtherResource, attrTypes: { someResource: 'Other' } },
        );
        resource = halResourceService.createHalResource(source, false);
      });

      it('should be an instance of that type', () => {
        expect(resource).toEqual(jasmine.any(OtherResource));
      });

      it('should have an attribute that is of the configured instance', () => {
        expect(resource.someResource).toEqual(jasmine.any(OtherResource));
      });

      it('should not be loaded', () => {
        expect(resource.someResource.$loaded).toBeFalsy();
      });
    });
  });

  describe('when after generating the lazy object', () => {
    let linkFn:Spy;
    let embeddedFn:Spy;

    beforeEach(() => {
      linkFn = jasmine.createSpy();
      embeddedFn = jasmine.createSpy();

      resource = halResourceService.createHalResource({
        _links: {
          get link() {
            linkFn();
            return {};
          },
        },
        _embedded: {
          get resource() {
            embeddedFn();
            return {};
          },
        },
      });
    });

    it('should not have touched the source links initially', () => {
      expect(linkFn.calls.count()).toEqual(0);
    });

    it('should not have touched the embedded elements of the source initially', () => {
      expect(embeddedFn.calls.count()).toEqual(0);
    });

    it('should use the source link only once when called', () => {
      resource.link;
      resource.link;
      expect(linkFn.calls.count()).toEqual(1);
    });

    it('should use the source embedded only once when called', () => {
      resource.resource;
      resource.resource;
      expect(embeddedFn.calls.count()).toEqual(1);
    });
  });

  describe('when the source has properties, the resource', () => {
    beforeEach(() => {
      source = {
        _links: {},
        _embedded: {},
        property: 'foo',
        obj: {
          foo: 'bar',
        },
      };
      resource = halResourceService.createHalResource(source, true);
    });

    it('should have the same properties', () => {
      expect(resource.property).toBeDefined();
      expect(resource.obj).toBeDefined();
    });

    it('should have properties with equal values', () => {
      expect(resource.property).toEqual(source.property);
      expect(resource.obj).toEqual(source.obj);
    });

    it('should not have the _links property', () => {
      expect(resource._links).toBeUndefined();
    });

    it('should not have the _embedded property', () => {
      expect(resource._embedded).toBeUndefined();
    });

    it('should have enumerable properties', () => {
      expect(resource.propertyIsEnumerable('property')).toBeTruthy();
    });

    describe('when a property is changed', () => {
      beforeEach(() => {
        resource.property = 'carrot';
      });

      it('should change the property of the source', () => {
        expect(resource.$source.property).toEqual('carrot');
      });
    });
  });

  describe('when creating a resource from a source with a self link', () => {
    beforeEach(() => {
      source = {
        _links: {
          self: {
            href: '/api/hello',
            title: 'some title',
          },
        },
      };
      resource = halResourceService.createHalResource(source, false);
    });

    it('should have a name attribute that is equal to the title of the self link', () => {
      expect(resource.name).toEqual('some title');
    });

    it('should have a writable name attribute', () => {
      resource.name = 'some name';
      expect(resource.name).toEqual('some name');
    });

    it('should have a href property that is the same as the self href', () => {
      expect(resource.href).toEqual(resource.$links.self.$link.href);
    });

    it('should have a href property that is equal to the source href', () => {
      expect(resource.href).toEqual(source._links.self.href);
    });

    it('should not have a self property', () => {
      expect(resource.self).toBeUndefined();
    });
  });

  describe('when setting a property that is a resource to null', () => {
    beforeEach(() => {
      source = {
        _links: {
          resource: {
            method: 'get',
            href: 'resource/1',
          },
        },
      };
      resource = halResourceService.createHalResource(source);
      resource.resource = null;
    });

    it('should be null', () => {
      expect(resource.resource).toBeNull();
    });

    it('should set the respective link href to null', () => {
      expect(resource.$source._links.resource.href).toBeNull();
    });
  });

  describe('when a property that is a resource has a null href', () => {
    beforeEach(() => {
      source = {
        _links: {
          property: {
            href: null,
          },
        },
      };
      resource = halResourceService.createHalResource(source);
    });

    it('should be null', () => {
      expect(resource.property).toBeNull();
    });
  });

  describe('when using $plain', () => {
    let plain:any;

    beforeEach(() => {
      source = {
        _links: { self: { href: 'bunny' } },
        rabbit: 'fluffy',
      };
      plain = halResourceService.createHalResource(source).$plain();
    });

    it('should return an object that is equal to the source', () => {
      expect(plain).toEqual(source);
    });

    it('should not be the exact same object', () => {
      expect(plain === source).toBeFalsy();
    });
  });

  describe('when creating a resource with a source that has no links', () => {
    beforeEach(() => {
      resource = halResourceService.createHalResource({});
    });

    it('should return null for the href if it has no self link', () => {
      expect(resource.href).toEqual(null);
    });

    it('should have a $link object with null href', () => {
      expect(resource.$link.href).toEqual(null);
    });
  });

  describe('when creating a resource form a source with linked resources', () => {
    beforeEach(() => {
      source = {
        _links: {
          self: {
            href: 'unicorn/69',
          },
          beaver: {
            href: 'justin/420',
          },
        },
      };
      resource = halResourceService.createHalResource(source);
    });

    it('should have no "self" property', () => {
      expect(resource.self).toBeUndefined();
    });

    it('should have a beaver', () => {
      expect(resource.beaver).toBeDefined();
    });

    it('should have no "_links" property', () => {
      expect(resource._links).toBeUndefined();
    });

    it('should leave the source accessible', () => {
      expect(resource.$source).toEqual(source);
    });

    it('should have a callable self link', () => {
      spyOn(halResourceService, 'request').and.callFake((verb:string, path:string) => {
        if (verb === 'get' && path === 'unicorn/69') {
          return of(halResourceService.createHalResource({})) as any;
        }
        return null as any;
      });

      expect(() => resource.$links.self()).not.toThrow(Error);
    });

    it('should have a callable beaver', () => {
      spyOn(halResourceService, 'request').and.callFake((verb:string, path:string) => {
        if (verb === 'get' && path === 'justin/420') {
          return of(halResourceService.createHalResource({})) as any;
        }
        return null as any;
      });

      expect(() => resource.$links.beaver()).not.toThrow(Error);
    });

    it('should have a $links property with the keys of its source _links', () => {
      const transformedLinks = Object.keys(resource.$links);
      const plainLinks = Object.keys(source._links);

      plainLinks.forEach((link:string) => {
        expect(resource.$links[link]).toBeDefined();
      });
    });
  });

  describe('when creating a resource from a source with embedded resources', () => {
    beforeEach(() => {
      source = {
        _embedded: {
          resource: { _links: {} },
        },
      };

      resource = halResourceService.createHalResource(source);
    });

    it('should not have the original _embedded property', () => {
      expect(resource._embedded).toBeUndefined();
    });

    it('should have a property, that is a loaded resource', () => {
      expect(resource.resource.$loaded).toBeTruthy();
    });

    it('should have an embedded resource, that is loaded', () => {
      expect(resource.$embedded.resource.$loaded).toBeTruthy();
    });

    it('should have a property that is the resource', () => {
      expect(resource.resource).toEqual(resource.$embedded.resource);
    });

    describe('when overriding the property with a resource', () => {
      let link:HalLinkInterface;

      beforeEach(() => {
        link = {
          href: 'pony',
          method: 'get',
        };
        resource.resource = HalLink.fromObject(halResourceService, link);
      });

      it('should set the property to that resource', () => {
        expect(resource.resource.href).toEqual(link.href);
      });
    });

    describe('when the embedded resources are nested', () => {
      let first:any;
      let deep:any;

      beforeEach(() => {
        source._embedded.resource._embedded = {
          first: {
            _embedded: {
              second: {
                _links: {},
                property: 'yet another value',
              },
            },
            property: 'another value',
          },
        };

        first = resource.$embedded.resource.$embedded.first;
        deep = resource.$embedded.resource.$embedded.first.$embedded.second;
      });

      it('should create all nested resources recursively', () => {
        expect(deep.$isHal).toBeTruthy();
      });

      it('should transfer the properties of the nested resources correctly', () => {
        expect(first.property).toEqual('another value');
        expect(deep.property).toEqual('yet another value');
      });
    });
  });

  describe('when creating a resource from a source with a linked array property', () => {
    const expectLengthsToBe = (length:any, update = 'update') => {
      it(`should ${update} the values of the resource`, () => {
        expect(resource.values.length).toEqual(length);
      });

      it(`should ${update} the source`, () => {
        expect(source._links.values.length).toEqual(length);
      });

      it(`should ${update} the $source property`, () => {
        expect(resource.$source._links.values.length).toEqual(length);
      });
    };

    beforeEach(() => {
      source = {
        _links: {
          values: [
            {
              href: '/api/value/1',
              title: 'val1',
            },
            {
              href: '/api/value/2',
              title: 'val2',
            },
          ],
        },
      };
      resource = halResourceService.createHalResource(source);
    });

    expectLengthsToBe(2);

    describe('when adding resources to the array', () => {
      beforeEach(() => {
        resource.values.push(resource);
      });
      expectLengthsToBe(3);
    });

    describe('when adding arbitrary values to the array', () => {
      beforeEach(() => {
        resource.values.push('something');
      });
      expectLengthsToBe(2, 'not update');
    });

    describe('when removing resources from the array', () => {
      beforeEach(() => {
        resource.values.pop();
      });
      expectLengthsToBe(1);
    });

    describe('when each value is transformed', () => {
      beforeEach(() => {
        resource = resource.values[0];
        source = source._links.values[0];
      });

      it('should have made each link a resource', () => {
        expect(resource.$isHal).toBeTruthy();
      });

      it('should be resources generated from the links', () => {
        expect(resource.href).toEqual(source.href);
      });

      it('should have a name attribute equal to the title of its link', () => {
        expect(resource.name).toEqual(source.title);
      });

      it('should not be loaded', () => {
        expect(resource.$loaded).toBeFalsy();
      });
    });
  });

  describe('when transforming an object with an _embedded list with the list element having _links', () => {
    beforeEach(() => {
      source = {
        _embedded: {
          elements: [{ _links: {} }, { _links: {} }],
        },
      };

      resource = halResourceService.createHalResource(source);
    });

    it('should not have the original _embedded property', () => {
      expect(resource._embedded).toBeUndefined();
    });

    it('should transform the list elements', () => {
      expect(resource.$embedded.elements[0].$isHal).toBeTruthy();
      expect(resource.$embedded.elements[1].$isHal).toBeTruthy();
    });
  });

  describe('when transforming an object with _links and _embedded', () => {
    beforeEach(() => {
      source = {
        _links: {
          property: {
            href: '/api/property',
            title: 'Property',
          },
          embedded: {
            href: '/api/embedded',
          },
          action: {
            href: '/api/action',
            method: 'post',
          },
          self: {
            href: '/api/self',
          },
        },
        _embedded: {
          embedded: {
            _links: {
              self: {
                href: '/api/embedded',
              },
            },
            name: 'name',
          },
          notLinked: {
            _links: {
              self: {
                href: '/api/not-linked',
              },
            },
          },
        },
      };

      resource = halResourceService.createHalResource(source);
    });

    it('should be loaded', () => {
      expect(resource.$loaded).toBeTruthy();
    });

    it('should not be possible to override a link', () => {
      try {
        resource.$links.action = 'foo';
      } catch (ignore) {
        /**/
      }

      expect(resource.$links.action).not.toEqual('foo');
    });

    it('should not be possible to override an embedded resource', () => {
      try {
        resource.$embedded.embedded = 'foo';
      } catch (ignore) {
        /**/
      }

      expect(resource.$embedded.embedded).not.toEqual('foo');
    });

    it('should have linked resources as properties', () => {
      expect(resource.property).toBeDefined();
    });

    it('should have linked actions as properties', () => {
      expect(resource.action).toBeDefined();
    });

    it('should have embedded resources as properties', () => {
      expect(resource.embedded).toBeDefined();
    });

    it('should have embedded, but not linked resources as properties', () => {
      expect(resource.notLinked).toBeDefined();
    });

    describe('when a resource that is linked and embedded is updated', () => {
      let embeddedResource;
      beforeEach(() => {
        embeddedResource = {
          $link: {
            method: 'get',
            href: 'newHref',
          },
        };

        resource.embedded = embeddedResource;
      });

      it('should update the source', () => {
        expect(resource.$source._links.embedded.href).toEqual('newHref');
      });
    });

    describe('when after generating the properties from the links, each property', () => {
      it('should be a function, if the link method is not "get"', () => {
        expect(typeof resource.action).toBe('function');
      });

      it('should be a resource, if the link method is "get"', () => {
        expect(resource.property.$isHal).toBeTruthy();
      });

      describe('when a property is a resource', () => {
        it('should not be callable', () => {
          expect(typeof resource.property).not.toEqual('function');
        });

        it('should not be loaded initially', () => {
          expect(resource.property.$loaded).toBeFalsy();
          expect(resource.notLinked.$loaded).toBeTruthy();
        });

        it('should be loaded, if the resource is embedded', () => {
          expect(resource.embedded.$loaded).toBeTruthy();
        });

        it('should update the source when set', () => {
          resource.property = resource;
          expect(resource.$source._links.property.href).toEqual('/api/self');
        });

        describe('when loading it', () => {
          let getStub:jasmine.Spy;
          let newResult:any;
          let promise:Promise<any>;

          beforeEach((done) => {
            const result = halResourceService.createHalResource({
              _links: {},
              name: 'name',
              foo: 'bar',
            });

            getStub = spyOn(halResourceService, 'request').and.callFake((verb:string, path:string) => {
              if (verb === 'get' && path === '/api/property') {
                return of(result) as any;
              }
              return false as any;
            });

            resource = resource.property;
            promise = resource.$load().then((result:HalResource) => {
              newResult = result;
            });

            expect(getStub).toHaveBeenCalled();
            done();
          });

          it('should be loaded', (done) => {
            promise.then(() => {
              expect(resource.$loaded).toBeTruthy();
              done();
            });
          });

          it('should be updated', () => {
            expect(newResult.name).toEqual('name');
          });

          it('should have properties that have a getter and setter', () => {
            const descriptor = Object.getOwnPropertyDescriptor(newResult, 'foo');
            expect(descriptor).toBeDefined('Descriptor should be defined');

            expect(descriptor!.get).toBeDefined('Descriptor getter should be defined');
            expect(descriptor!.set).toBeDefined('Descriptor setter should be defined');
          });

          it('should return itself in a promise if already loaded', () => {
            resource.$loaded = true;

            resource.$load().then((result:HalResource) => {
              expect(result).toEqual(resource);
            });
          });
        });
      });
    });
  });
});
