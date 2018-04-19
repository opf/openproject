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

import {async, TestBed} from '@angular/core/testing';
import {OpenprojectHalModule} from 'core-app/modules/hal/openproject-hal.module';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {Injector} from '@angular/core';
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {SinonStub} from 'sinon';
import {HalLink, HalLinkInterface} from 'core-app/modules/hal/hal-link/hal-link';
import {States} from 'core-components/states.service';
import {TypeDmService} from 'core-app/modules/hal/dm-services/type-dm.service';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {Observable} from 'rxjs';

describe('HalResource', () => {
  let halResourceService:HalResourceService;
  let injector:Injector;

  let source:any;
  let resource:HalResource;

  class OtherResource extends HalResource {
  }

  beforeEach(async(() => {
    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      imports: [
        OpenprojectHalModule
      ],
      providers: [
        HalResourceService,
        States,
        TypeDmService,
        { provide: I18nToken, useValue: {} },
      ]
    })
      .compileComponents()
      .then(() => {
        halResourceService = TestBed.get(HalResourceService);
        injector = TestBed.get(Injector);
      });
  }));

  it('should be instantiable using a default object', () => {
    let resource = halResourceService.createHalResource({}, true);
    expect(resource.$href).to.equal(null);
  });

  describe('when updating a loaded resource using `$update()`', () => {
    let getStub:SinonStub;

    beforeEach(() => {
      source = {
        _links: {
          self: {
            href: '/api/hello'
          }
        }
      };

      getStub = sinon.stub(halResourceService, 'request');
      getStub
        .withArgs('get', '/api/hello')
        .returns(Observable.of(halResourceService.createHalResource(source)));
    });

    afterEach(() => {
      getStub.restore();
    });

    it('should perform a request', () => {
      resource = halResourceService.createHalResource(source, true);
      resource.$update();
      expect(getStub).to.have.been.called;
    });
  });

  describe('when creating a resource using the create factory method', () => {
    describe('when there is no type configuration', () => {
      beforeEach(() => {
        source = {_embedded: {}};
        resource = halResourceService.createHalResource(source, true);
      });

      it('should be an instance of HalResource', () => {
        expect(resource).to.be.an.instanceOf(HalResource);
      });
    });

    describe('when the type is configured', () => {
      beforeEach(() => {
        source = {
          _type: 'Other',
          _links: {
            someResource: {
              href: 'foo'
            }
          }
        };

        halResourceService.registerResource(
          'Other',
          { cls: OtherResource, attrTypes: { someResource: 'Other' } }
          );
        resource = halResourceService.createHalResource(source, false);
      });

      it('should be an instance of that type', () => {
        expect(resource).to.be.an.instanceOf(OtherResource);
      });

      it('should have an attribute that is of the configured instance', () => {
        expect(resource.someResource).to.be.an.instanceOf(OtherResource);
      });

      it('should not be loaded', () => {
        expect(resource.someResource.$loaded).to.be.false;
      });
    });
  });

  describe('when after generating the lazy object', () => {
    var linkFn = sinon.spy();
    var embeddedFn = sinon.spy();

    beforeEach(() => {
      resource = halResourceService.createHalResource({
        _links: {
          get link() {
            linkFn();
            return {};
          }
        },
        _embedded: {
          get resource() {
            embeddedFn();
            return {};
          }
        }
      });
    });

    it('should not have touched the source links initially', () => {
      expect(linkFn.called).to.be.false;
    });

    it('should not have touched the embedded elements of the source initially', () => {
      expect(embeddedFn.called).to.be.false;
    });

    it('should use the source link only once when called', () => {
      resource.link;
      resource.link;
      expect(linkFn.calledOnce).to.be.true;
    });

    it('should use the source embedded only once when called', () => {
      resource.resource;
      resource.resource;
      expect(embeddedFn.calledOnce).to.be.true;
    });
  });

  describe('when the source has properties, the resource', () => {
    beforeEach(() => {
      source = {
        _links: {},
        _embedded: {},
        property: 'foo',
        obj: {
          foo: 'bar'
        }
      };
      resource = halResourceService.createHalResource(source, true);
    });

    it('should have the same properties', () => {
      expect(resource.property).to.exist;
      expect(resource.obj).to.exist;
    });

    it('should have properties with equal values', () => {
      expect(resource.property).to.eq(source.property);
      expect(resource.obj).to.eql(source.obj);
    });

    it('should not have the _links property', () => {
      expect(resource._links).to.not.exist;
    });

    it('should not have the _embedded property', () => {
      expect(resource._embedded).to.not.exist;
    });

    it('should have enumerable properties', () => {
      expect(resource.propertyIsEnumerable('property')).to.be.true;
    });

    describe('when a property is changed', () => {
      beforeEach(() => {
        resource.property = 'carrot';
      });

      it('should change the property of the source', () => {
        expect(resource.$source.property).to.eq('carrot');
      });
    });
  });

  describe('when creating a resource from a source with a self link', () => {
    beforeEach(() => {
      source = {
        _links: {
          self: {
            href: '/api/hello',
            title: 'some title'
          }
        }
      };
      resource = halResourceService.createHalResource(source, false);
    });

    it('should have a name attribute that is equal to the title of the self link', () => {
      expect(resource.name).to.eq('some title');
    });

    it('should have a writable name attribute', () => {
      resource.name = 'some name';
      expect(resource.name).to.eq('some name');
    });

    it('should have a href property that is the same as the self href', () => {
      expect(resource.href).to.eq(resource.$links.self.$link.href);
    });

    it('should have a href property that is equal to the source href', () => {
      expect(resource.href).to.eq(source._links.self.href);
    });

    it('should not have a self property', () => {
      expect(resource.self).not.to.exist;
    });
  });

  describe('when setting a property that is a resource to null', () => {
    beforeEach(() => {
      source = {
        _links: {
          resource: {
            method: 'get',
            href: 'resource/1'
          }
        }
      };
      resource = halResourceService.createHalResource(source);
      resource.resource = null;
    });

    it('should be null', () => {
      expect(resource.resource).to.be.null;
    });

    it('should set the respective link href to null', () => {
      expect(resource.$source._links.resource.href).to.be.null;
    });
  });

  describe('when a property that is a resource has a null href', () => {
    beforeEach(() => {
      source = {
        _links: {
          property: {
            href: null
          }
        }
      };
      resource = halResourceService.createHalResource(source);
    });

    it('should be null', () => {
      expect(resource.property).to.be.null;
    });
  });

  describe('when using $plain', () => {
    var plain:any;

    beforeEach(() => {
      source = {
        _links: {self: {href: 'bunny'}},
        rabbit: 'fluffy'
      };
      plain = halResourceService.createHalResource(source).$plain();
    });

    it('should return an object that is equal to the source', () => {
      expect(plain).to.eql(source);
    });

    it('should not be the exact same object', () => {
      expect(plain).not.to.equal(source);
    });
  });

  describe('when creating a resource with a source that has no links', () => {
    beforeEach(() => {
      resource = halResourceService.createHalResource({});
    });

    it('should return null for the href if it has no self link', () => {
      expect(resource.href).to.equal(null);
    });

    it('should have a $link object with null href', () => {
      expect(resource.$link.href).to.equal(null);
    });
  });

  describe('when creating a resource form a source with linked resources', () => {
    beforeEach(() => {
      source = {
        _links: {
          self: {
            href: 'unicorn/69'
          },
          beaver: {
            href: 'justin/420'
          }
        }
      };
      resource = halResourceService.createHalResource(source);
    });

    it('should have no "self" property', () => {
      expect(resource.self).to.not.exist;
    });

    it('should have a beaver', () => {
      expect(resource.beaver).to.exist;
    });

    it('should have no "_links" property', () => {
      expect(resource._links).to.not.exist;
    });

    it('should leave the source accessible', () => {
      expect(resource.$source).to.eql(source);
    });

    it('should have a callable self link', () => {
      let stub = sinon.stub(halResourceService, 'request');
      stub
        .withArgs('get', 'unicorn/69')
        .returns(Observable.of(halResourceService.createHalResource({})));

      expect(() => resource.$links.self()).to.not.throw(Error);
      stub.restore();
    });

    it('should have a callable beaver', () => {
      let stub = sinon.stub(halResourceService, 'request');
      stub
        .withArgs('get', 'justin/420')
        .returns(Observable.of(halResourceService.createHalResource({})));

      expect(() => resource.$links.beaver()).to.not.throw(Error);

      stub.restore();
    });

    it('should have a $links property with the keys of its source _links', () => {
      const transformedLinks = Object.keys(resource.$links);
      const plainLinks = Object.keys(source._links);

      expect(transformedLinks).to.have.members(plainLinks);
    });
  });

  describe('when creating a resource from a source with embedded resources', () => {
    beforeEach(() => {
      source = {
        _embedded: {
          resource: {_links: {}},
        }
      };

      resource = halResourceService.createHalResource(source);
    });

    it('should not have the original _embedded property', () => {
      expect(resource._embedded).to.not.be.ok;
    });

    it('should have a property, that is a loaded resource', () => {
      expect(resource.resource.$loaded).to.be.true;
    });

    it('should have an embedded resource, that is loaded', () => {
      expect(resource.$embedded.resource.$loaded).to.be.true;
    });

    it('should have a property that is the resource', () => {
      expect(resource.resource).to.equal(resource.$embedded.resource);
    });

    describe('when overriding the property with a resource', () => {
      var link:HalLinkInterface;

      beforeEach(() => {
        link = {
          href: 'pony',
          method: 'get'
        };
        resource.resource = HalLink.fromObject(halResourceService, link);
      });

      it('should set the property to that resource', () => {
        expect(resource.resource.href).to.equal(link.href);
      });
    });

    describe('when the embedded resources are nested', () => {
      var first:any;
      var deep:any;

      beforeEach(() => {
        source._embedded.resource._embedded = {
          first: {
            _embedded: {
              second: {
                _links: {},
                property: 'yet another value'
              }
            },
            property: 'another value'
          }
        };

        first = resource.$embedded.resource.$embedded.first;
        deep = resource.$embedded.resource.$embedded.first.$embedded.second;
      });

      it('should crate all nested resources recursively', () => {
        expect(deep.$isHal).to.be.true;
      });

      it('should transfer the properties of the nested resources correctly', () => {
        expect(first.property).to.eq('another value');
        expect(deep.property).to.eq('yet another value');
      });
    });
  });

  describe('when creating a resource from a source with a linked array property', () => {
    var expectLengthsToBe = (length:any, update = 'update') => {
      it(`should ${update} the values of the resource`, () => {
        expect(resource.values).to.have.lengthOf(length);
      });

      it(`should ${update} the source`, () => {
        expect(source._links.values).to.have.lengthOf(length);
      });

      it(`should ${update} the $source property`, () => {
        expect(resource.$source._links.values).to.have.lengthOf(length);
      });
    };

    beforeEach(() => {
      source = {
        _links: {
          values: [
            {
              href: '/api/value/1',
              title: 'val1'
            },
            {
              href: '/api/value/2',
              title: 'val2'
            }
          ]
        }
      };
      resource = halResourceService.createHalResource(source);
    });

    it('should be an array that is a property of the resource', () => {
      expect(resource).to.have.property('values').that.is.an('array');
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
        expect(resource.$isHal).to.be.true;
      });

      it('should be resources generated from the links', () => {
        expect(resource.href).to.eq(source.href);
      });

      it('should have a name attribute equal to the title of its link', () => {
        expect(resource.name).to.eq(source.title);
      });

      it('should not be loaded', () => {
        expect(resource.$loaded).to.be.false;
      });
    });
  });

  describe('when transforming an object with an _embedded list with the list element having _links', () => {
    beforeEach(() => {
      source = {
        _embedded: {
          elements: [{_links: {}}, {_links: {}}]
        }
      };

      resource = halResourceService.createHalResource(source);
    });

    it('should not have the original _embedded property', () => {
      expect(resource._embedded).to.not.be.ok;
    });

    it('should transform the list elements', () => {
      expect(resource.$embedded.elements[0].$isHal).to.be.true;
      expect(resource.$embedded.elements[1].$isHal).to.be.true;
    });
  });

  describe('when transforming an object with _links and _embedded', () => {
    beforeEach(() => {
      source = {
        _links: {
          property: {
            href: '/api/property',
            title: 'Property'
          },
          embedded: {
            href: '/api/embedded',
          },
          action: {
            href: '/api/action',
            method: 'post'
          },
          self: {
            href: '/api/self'
          }
        },
        _embedded: {
          embedded: {
            _links: {
              self: {
                href: '/api/embedded'
              }
            },
            name: 'name'
          },
          notLinked: {
            _links: {
              self: {
                href: '/api/not-linked'
              }
            }
          }
        }
      };

      resource = halResourceService.createHalResource(source);
    });

    it('should be loaded', () => {
      expect(resource.$loaded).to.be.true;
    });

    it('should not be possible to override a link', () => {
      try {
        resource.$links.action = 'foo';
      } catch (ignore) {
        /**/
      }

      expect(resource.$links.action).to.not.eq('foo');
    });

    it('should not be possible to override an embedded resource', () => {
      try {
        resource.$embedded.embedded = 'foo';
      } catch (ignore) {
        /**/
      }

      expect(resource.$embedded.embedded).to.not.eq('foo');
    });

    it('should have linked resources as properties', () => {
      expect(resource.property).to.exist;
    });

    it('should have linked actions as properties', () => {
      expect(resource.action).to.exist;
    });

    it('should have embedded resources as properties', () => {
      expect(resource.embedded).to.exist;
    });

    it('should have embedded, but not linked resources as properties', () => {
      expect(resource.notLinked).to.exist;
    });

    describe('when a resource that is linked and embedded is updated', () => {
      var embeddedResource;
      beforeEach(() => {
        embeddedResource = {
          $link: {
            method: 'get',
            href: 'newHref'
          }
        };

        resource.embedded = embeddedResource;
      });

      it('should update the source', () => {
        expect(resource.$source._links.embedded.href).to.eq('newHref');
      });
    });

    describe('when after generating the properties from the links, each property', () => {
      it('should be a function, if the link method is not "get"', () => {
        expect(resource).to.respondTo('action');
      });

      it('should be a resource, if the link method is "get"', () => {
        expect(resource.property.$isHal).to.be.true;
      });

      describe('when a property is a resource', () => {
        it('should not be callable', () => {
          expect(resource).to.not.to.respondTo('property');
        });

        it('should not be loaded initially', () => {
          expect(resource.property.$loaded).to.be.false;
          expect(resource.notLinked.$loaded).to.be.true;
        });

        it('should be loaded, if the resource is embedded', () => {
          expect(resource.embedded.$loaded).to.be.true;
        });

        it('should update the source when set', () => {
          resource.property = resource;
          expect(resource.$source._links.property.href).to.eql('/api/self');
        });

        describe('when loading it', () => {
          let getStub:SinonStub;

          beforeEach(() => {
            let result = halResourceService.createHalResource({
              _links: {},
              name: 'name',
              foo: 'bar'
            });

            getStub = sinon.stub(halResourceService, 'request');

            getStub
              .withArgs('get', '/api/property')
              .returns(Observable.of(result));

            resource = resource.property;
            resource.$load();

            expect(getStub).to.have.been.called;
          });

          afterEach(() => {
            getStub.restore();
          });

          it('should be loaded', () => {
            expect(resource.$loaded).to.be.true;
          });

          it('should be updated', () => {
            expect(resource.name).to.eq('name');
          });

          it('should have properties that have a getter', () => {
            expect((Object as any).getOwnPropertyDescriptor(resource, 'foo').get).to.exist;
          });

          it('should have properties that have a setter', () => {
            expect((Object as any).getOwnPropertyDescriptor(resource, 'foo').set).to.exist;
          });

          it('should return itself in a promise if already loaded', () => {
            resource.$loaded = true;

            expect(resource.$load()).to.eventually.be.fulfilled.then(result => {
              expect(result).to.equal(result);
            });
          });
        });
      });
    });
  });
});
