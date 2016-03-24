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

const expect = chai.expect;

describe('HalResource service', () => {
  var HalResource;
  var $httpBackend:ng.IHttpBackendService;
  var NotificationsService;

  beforeEach(angular.mock.module('openproject.api'));
  beforeEach(angular.mock.module('openproject.services'));

  beforeEach(angular.mock.inject((_HalResource_, _$httpBackend_, _NotificationsService_) => {
    NotificationsService = _NotificationsService_;
    HalResource = _HalResource_;
    $httpBackend = _$httpBackend_;
  }));

  it('should exist', () => {
    expect(HalResource).to.exist;
  });

  it('should set its source to _plain if _plain is a property of the source', () => {
    let source = {
      _plain: {
        _links: {},
        prop: true
      }
    };
    let resource = new HalResource(source);

    expect(resource.prop).to.exist;
  });

  describe('when after generating the lazy object', () => {
    var resource;
    var linkFn = sinon.spy();
    var embeddedFn = sinon.spy();

    beforeEach(() => {
      resource = new HalResource({
        _links: {
          get link() {
            linkFn();
            return {};
          }
        },
        _embedded: {
          get res() {
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
      resource.$links.link;
      resource.$links.link;
      expect(linkFn.calledOnce).to.be.true;
    });

    it('should use the source embedded only once when called', () => {
      resource.$embedded.res;
      resource.$embedded.res;
      expect(embeddedFn.calledOnce).to.be.true;
    });
  });

  describe('when the source has properties', () => {
    var resource;
    beforeEach(() => {
      resource = new HalResource({
        _links: {},
        _embedded: {},
        property: 'foo',
        obj: {
          foo: 'bar'
        }
      });
    });

    it('should have the same properties', () => {
      expect(resource.property).to.exist;
      expect(resource.obj).to.exist;
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

  describe('when transforming an object with _links', () => {
    var plain;
    var resource;

    beforeEach(() => {
      plain = {
        _type: 'Hello',
        _links: {
          post: {
            href: '/api/v3/hello',
            method: 'post'
          },
          put: {
            href: '/api/v3/hello',
            method: 'put'
          },
          patch: {
            href: '/api/v3/hello',
            method: 'patch'
          },
          'get': {
            href: '/api/v3/hello',
          },
          'delete': {
            href: '/api/v3/hello',
            method: 'delete'
          },
          self: {
            href: '/api/v3/hello',
            title: 'some title'
          }
        }
      };

      resource = new HalResource(plain);
    });

    it('should be transformed', () => {
      expect(resource.$isHal).to.be.true;
    });

    it('should have a href property that is the same as the self href', () => {
      expect(resource.href).to.eq(resource.$links.self.$link.href);
    });

    it('should return an empty $embedded object', () => {
      expect(resource.$embedded).to.eql({});
    });

    describe('when the self link has a title attribute', () => {
      beforeEach(() => {
        resource = new HalResource({
          _links: {
            self: {
              href: '/api/hello',
              title: 'some title'
            }
          }
        });
      });

      it('should have a name attribute that is equal to the title of the self link', () => {
        expect(resource.name).to.eq('some title');
      });

      it('should have a writable name attribute', () => {
        resource.name = 'some name';
        expect(resource.name).to.eq('some name');
      });
    });

    //TODO: Fix
    describe.skip('when returning back the plain object', () => {
      var element;
      beforeEach(() => {
        element = resource.$plain();
      });

      it('should be the same as the source element', () => {
        expect(element).to.eql(plain);
      });
    });

    describe('when after the $links property is generated', () => {
      it('should exist', () => {
        expect(resource.$links).to.exist;
      });

      it('should not have the original `_links` property', () => {
        expect(resource._links).to.not.exist;
      });

      it('should have callable links', () => {
        expect(resource.$links).to.respondTo('self');
        expect(resource.$links).to.respondTo('put');
        expect(resource.$links).to.respondTo('post');
      });

      it('should not be restangularized', () => {
        expect(resource.$links.restangularized).to.not.be.ok;
      });

      it('should have a links property with the same keys as the original _links', () => {
        const transformedLinks = Object.keys(resource.$links);
        const plainLinks = Object.keys(plain._links);

        expect(transformedLinks).to.have.members(plainLinks);
      });
    });
  });

  describe('when transforming an object with _embedded', () => {
    var plain;
    var resource;

    beforeEach(() => {
      plain = {
        _type: 'Hello',
        _embedded: {
          resource: {
            _links: {
            },
            _embedded: {
              first: {
                _embedded: {
                  second: {
                    _links: {},
                    property: 'yet another value'
                  }
                },
                property: 'another value'

              }
            },
            propertyResource: {
              _links: {}
            }
          },
          property: 'value'
        }
      };

      resource = new HalResource(plain);
    });

    it('should return an empty $links object', () => {
      expect(resource.$links).to.eql({});
    });

    it('should not be restangularized', () => {
      expect(resource.restangularized).to.not.be.ok;
    });

    it('should be transformed', () => {
      expect(resource.$isHal).to.be.true
    });

    it('should have a new "embedded" property', () => {
      expect(resource.$embedded);
    });

    it('should not have the original _embedded property', () => {
      expect(resource._embedded).to.not.be.ok;
    });

    it('should transform its resources', () => {
      expect(resource.$embedded.resource.$isHal).to.be.true;
    });

    it('should not transform its properties', () => {
      expect(resource.$embedded.property.$isHal).to.not.be.ok;
    });

    describe('when transforming nested embedded resources', () => {
      var first;
      var second;

      beforeEach(() => {
        first = resource.$embedded.resource.$embedded.first;
        second = resource.$embedded.resource.$embedded.first.$embedded.second;
      });

      it('should transform properties that are resources', () => {
        expect(resource.$embedded.resource.propertyResource.$isHal).to.be.true;
      });

      it('should transform all nested resources recursively', () => {
        expect(first.$isHal).to.be.true;
        expect(second.$isHal).to.be.true;
      });

      it('should transfer the properties of the nested resources correctly', () => {
        expect(first.property).to.eq('another value');
        expect(second.property).to.eq('yet another value');
      });
    });
  });

  describe('when transforming an object with a links property that is an array', () => {
    var resource;

    beforeEach(() => {
      resource = new HalResource({
        _links: {
          values: [
            {
              href: '/api/value/1'
            },
            {
              href: '/api/value/2'
            }
          ]
        }
      });
    });

    it('should be an array of links in $links', () => {
      expect(Array.isArray(resource.$links.values)).to.be.true;
    });

    it('should should be the same amount of items as the original', () => {
      expect(resource.$links.values.length).to.eq(2);
    });

    it('should have made each link callable', () => {
      expect(resource.$links.values[0]).to.not.throw(Error);
    });

    it('should be an array that is a property of the resource', () => {
      expect(Array.isArray(resource.values)).to.be.true;
    });
  });

  describe('when transforming an object with an _embedded list with the list element having _links', () => {
    var plain;
    var resource;

    beforeEach(() => {
      plain = {
        _type: 'Hello',
        _embedded: {
          elements: [
            { _type: 'ListElement',
              _links: {}
            },
            { _type: 'ListElement',
              _links: {}
            }
          ]
        }
      };

      resource = new HalResource(plain);
    });

    it('should not be restangularized', () => {
      expect(resource.restangularized).to.not.be.ok;
    });

    it('should be transformed', () => {
      expect(resource.$isHal).to.be.true
    });

    it('should have a new "embedded" property', () => {
      expect(resource.$embedded);
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
    var resource;

    beforeEach(() => {
      const plain = {
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

      resource = new HalResource(plain);
    });

    it('should be loaded', () => {
      expect(resource.$loaded).to.be.true;
    });

    it('should not be possible to override a link', () => {
      try {
        resource.$links.action = 'foo';
      }
      catch (Error) {}

      expect(resource.$links.action).to.not.eq('foo');
    });

    it('should not be possible to override an embedded resource', () => {
      try {
        resource.$embedded.embedded = 'foo';
      }
      catch (Error) {}

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

    it('should have embedded, but not linked, resources as properties', () => {
      expect(resource.notLinked).to.exist;
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
          expect(resource.$source._links.property.href).to.eql('/api/self')
        });

        describe('when loading it', () => {
          beforeEach(() => {
            resource = resource.property;
            resource.$load();

            $httpBackend.expectGET('/api/property').respond(200, {
              name: 'name'
            });
            $httpBackend.flush();
          });

          it('should be loaded', () => {
            expect(resource.$loaded).to.be.true;
          });

          it('should be updated', () => {
            expect(resource.name).to.eq('name');
          });

          it('should return itself in a promise if already loaded', () => {
            expect(resource.$load()).to.eventually.eql(resource);
          });
        });
      });
    });
  });
});
