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

describe('halTransform service', () => {
  var halTransform;
  var $httpBackend:ng.IHttpBackendService;

  beforeEach(angular.mock.module('openproject.api'));

  beforeEach(angular.mock.inject((_halTransform_, _$httpBackend_) => {
    halTransform = _halTransform_;
    $httpBackend = _$httpBackend_;
  }));

  it('should exist', () => {
    expect(halTransform).to.exist;
  });

  describe('when transforming an object without _links or _embedded', () => {
    var element;

    beforeEach(() => {
      element = halTransform({});
    });

    it('should return the element as it is', () => {
      expect(element).to.eq(element);
    });

    it('should not be halTransformed', () => {
      expect(element.$halTransformed).to.not.be.ok;
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
          }
        }
      };

      transformedElement = halTransform(angular.copy(plainElement));
    });

    it('should be restangularized', () => {
      expect(transformedElement.restangularized).to.not.be.ok;
    });

    it('should be transformed', () => {
      expect(transformedElement.$halTransformed).to.be.true;
    });

    describe('when returning back the plain object', () => {
      var element;
      beforeEach(() => {
        element = transformedElement.$plain();
      });

      //TODO: Fix
      it.skip('should be the same as the source element', () => {
        expect(element).to.eql(plainElement);
      });
    });

    describe('when after the $links property is generated', () => {
      it('should exist', () => {
        expect(transformedElement.$links).to.exist;
      });

      it('should not have the original `_links` property', () => {
        expect(transformedElement._links).to.not.exist;
      });

      it('should not be restangularized', () => {
        expect(transformedElement.$links.restangularized).to.not.be.ok;
      });

      it('should have a links property with the same keys as the original _links', () => {
        const transformedLinks = Object.keys(transformedElement.$links);
        const plainLinks = Object.keys(plainElement._links);

        expect(transformedLinks).to.have.members(plainLinks);
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

      transformedElement = halTransform(angular.copy(plainElement));
    });

    it('should not be restangularized', () => {
      expect(transformedElement.restangularized).to.not.be.ok;
    });

    it('should be transformed', () => {
      expect(transformedElement.$halTransformed).to.be.true
    });

    it('should have a new "embedded" property', () => {
      expect(transformedElement.$embedded);
    });

    it('should not have the original _embedded property', () => {
      expect(transformedElement._embedded).to.not.be.ok;
    });

    it('should transform its resources', () => {
      expect(transformedElement.$embedded.resource.$halTransformed).to.be.true;
    });

    it('should not transform its properties', () => {
      expect(transformedElement.$embedded.property.$halTransformed).to.not.be.ok;
    });

    describe('when transforming nested embedded resources', () => {
      var first;
      var second;

      beforeEach(() => {
        first = transformedElement.$embedded.resource.$embedded.first;
        second = transformedElement.$embedded.resource.$embedded.first.$embedded.second;
      });

      it('should transform properties that are resources', () => {
        expect(transformedElement.$embedded.resource.propertyResource.$halTransformed).to.be.true;
      });

      it('should transform all nested resources recursively', () => {
        expect(first.$halTransformed).to.be.true;
        expect(second.$halTransformed).to.be.true;
      });

      it('should transfer the properties of the nested resources correctly', () => {
        expect(first.property).to.eq('another value');
        expect(second.property).to.eq('yet another value');
      });
    });
  });

  describe('when transforming an object with an _embedded list with the list element having _links', () => {
    var plainElement;
    var transformedElement;

    beforeEach(() => {
      plainElement = {
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

      transformedElement = halTransform(angular.copy(plainElement));
    });

    it('should not be restangularized', () => {
      expect(transformedElement.restangularized).to.not.be.ok;
    });

    it('should be transformed', () => {
      expect(transformedElement.$halTransformed).to.be.true
    });

    it('should have a new "embedded" property', () => {
      expect(transformedElement.$embedded);
    });

    it('should not have the original _embedded property', () => {
      expect(transformedElement._embedded).to.not.be.ok;
    });

    it('should transform the list elements', () => {
      expect(transformedElement.$embedded.elements[0].$halTransformed).to.be.true;
      expect(transformedElement.$embedded.elements[1].$halTransformed).to.be.true;
    });
  });

  //TODO: Implement distinction between linked actions and properties
  describe.skip('when transforming an object with _links and/or _embedded', () => {
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

      transformedElement = halTransform(plainElement);
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
        let promise = transformedElement.$links.property();

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
