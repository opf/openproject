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

describe('HalTransformedElementService', () => {
  var HalTransformedElement:op.HalTransformed;
  var $httpBackend:ng.IHttpBackendService;

  beforeEach(angular.mock.module('openproject.api'));

  beforeEach(angular.mock.inject((_HalTransformedElement_, _$httpBackend_) => {
    HalTransformedElement = _HalTransformedElement_;
    $httpBackend = _$httpBackend_;
  }));

  afterEach(() => {
    $httpBackend.verifyNoOutstandingExpectation();
    $httpBackend.verifyNoOutstandingRequest();
  });

  it('should exist', () => {
    expect(HalTransformedElement).to.exist;
  });

  describe('when transforming an object without _links or _embedded', () => {
    var elementMock = {};

    it('should return the element as it is', () => {
      const element = new HalTransformedElement(elementMock);
      expect(element).to.eq(elementMock);
    });
  });

  describe('when transforming an object with _links', () => {
    var plainElement;
    var transformedElement;

    beforeEach(() => {
      plainElement = {
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
          },
          nullHref: {
            href: null
          }
        }
      };

      transformedElement = new HalTransformedElement(angular.copy(plainElement));
    });

    it('should be restangularized', () => {
      expect(transformedElement.restangularized).to.be.true;
    });

    it('should be transformed', () => {
      expect(transformedElement.halTransformed).to.be.true;
    });

    describe('when after the links property is generated', () => {
      it('should exist', () => {
        expect(transformedElement.links).to.exist;
      });

      it('should not have the original `_links` property', () => {
        expect(transformedElement._links).to.not.exist;
      });

      it('should not be restangularized', () => {
        expect(transformedElement.links.restangularized).to.not.be.ok;
      });

      it('should not be transformed', () => {
        expect(transformedElement.links.transformed).to.not.be.ok;
      });

      it('should have a links property with the same keys as the original _links', () => {
        const transformedLinks = Object.keys(transformedElement.links);
        const plainLinks = Object.keys(plainElement._links);

        expect(transformedLinks).to.have.members(plainLinks);
      });
    });

    describe('when a link has a null href', () => {
      it('should return a promise with an empty object', () => {
        expect(transformedElement.links.nullHref()).to.eventually.eql({});
      });
    });

    describe('when using one of the generated links', () => {
      it('should be callable', () => {
        expect(transformedElement.links).to.respondTo('get');
        expect(transformedElement.links).to.respondTo('put');
        expect(transformedElement.links).to.respondTo('patch');
        expect(transformedElement.links).to.respondTo('post');
        expect(transformedElement.links).to.respondTo('delete');
      });

      it('should return the requested value as a promise', () => {
        var promise = transformedElement.links.get();
        var response = {hello: 'world'};

        $httpBackend.expectGET('/api/v3/hello').respond(200, response);
        $httpBackend.flush();

        promise.should.be.fulfilled.then(value => {
          expect(value.hello).to.eq(response.hello);
        })
      });

      it('should perform a GET request by default', () => {
        transformedElement.links.get();
        $httpBackend.expectGET('/api/v3/hello').respond(200);
        $httpBackend.flush();
      });

      it('should perform a POST request', () => {
        transformedElement.links.post();
        $httpBackend.expectPOST('/api/v3/hello').respond(200);
        $httpBackend.flush();
      });

      it('should perform a PUT request', () => {
        transformedElement.links.put();
        $httpBackend.expectPUT('/api/v3/hello').respond(200);
        $httpBackend.flush();
      });

      it('should perform a PATCH request', () => {
        transformedElement.links.patch();
        $httpBackend.expectPATCH('/api/v3/hello').respond(200);
        $httpBackend.flush();
      });

      describe('when using the list method of a single link', () => {
        it('should exist', () => {
          expect(transformedElement.links.get.list).to.exist;
        });

        it('should perform a GET request', () => {
          transformedElement.links.get.list();
          $httpBackend.expectGET('/api/v3/hello').respond(200);
          $httpBackend.flush();
        });
      });
    });
  });

  describe('when transforming an object with _embedded', () => {
    var plainElement;
    var transformedElement;

    beforeEach(() => {
      plainElement = {
        _type: 'Hello',
        _embedded: {
          resource: {
            _links: {
            },
            _embedded: {
              first: {
                _embedded: {
                  second: {
                    _links: {}
                  }
                }
              }
            }
          },
          property: 'value'
        }
      };

      transformedElement = new HalTransformedElement(angular.copy(plainElement));
    });

    it('should be restangularized', () => {
      expect(transformedElement.restangularized).to.be.true;
    });

    it('should be transformed', () => {
      expect(transformedElement.halTransformed).to.be.true
    });

    it('should have a new "embedded" property', () => {
      expect(transformedElement.embedded);
    });

    it('should not have the original _embedded property', () => {
      expect(transformedElement._embedded).to.not.be.ok;
    });

    it('should transform its resources', () => {
      expect(transformedElement.embedded.resource.halTransformed).to.be.true;
    });

    it('should not transform its properties', () => {
      expect(transformedElement.embedded.property.halTransformed).to.not.be.ok;
    });

    it('should transform all nested resources recursively', () => {
      var first = transformedElement.embedded.resource.embedded.first;
      var second = transformedElement.embedded.resource.embedded.first.embedded.second;

      expect(first.halTransformed && first.restangularized).to.be.true;
      expect(second.halTransformed && second.restangularized).to.be.true;
    });
  });

  describe('when transforming an object with _links and/or _embedded', () => {
    var transformedElement;

    beforeEach(() => {
      const plainElement = {
        _links: {
          property: {
            href: '/api/property',
            title: 'Property'
          },
          embeddedProperty: {
            href: '/api/embedded-property'
          },
          action: {
            href: '/api/action',
            method: 'post'
          }
        },
        _embedded: {
          embeddedProperty: {
            name: 'name'
          }
        }
      };

      transformedElement = new HalTransformedElement(plainElement);
    });

    it('should be a property of the element', () => {
      expect(transformedElement.property).to.exist;
      expect(transformedElement.embeddedProperty).to.exist;
      expect(transformedElement.action).to.exist;
    });

    describe('when using one of the properties', () => {
      it('should have the same properties as the original', () => {
        expect(transformedElement.property.href).to.eq('/api/property');
        expect(transformedElement.property.title).to.eq('Property');
      });

      it('should update the property when its link is called', () => {
        let promise = transformedElement.links.property();

        $httpBackend.expectGET('/api/property').respond(200, {
          name: 'Name'
        });
        $httpBackend.flush();

        promise.should.be.fulfilled.then(() => {
          expect(transformedElement.property.name).to.eq('Name');
        });
      });
    });
  });
});
