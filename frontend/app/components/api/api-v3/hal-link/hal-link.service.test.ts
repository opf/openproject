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

import {opApiModule, opServicesModule} from '../../../../angular-modules';
import {HalLink} from './hal-link.service';

describe('HalLink service', () => {
  var $httpBackend:ng.IHttpBackendService;
  var $rootScope;
  var HalLink;
  var apiV3;
  var link:HalLink;

  beforeEach(angular.mock.module(opApiModule.name, opServicesModule.name));
  beforeEach(angular.mock.inject(function (_$httpBackend_,
                                           _$rootScope_,
                                           _apiV3_,
                                           _HalLink_) {
    [$httpBackend, $rootScope, apiV3, HalLink] = _.toArray(arguments);

    apiV3.setDefaultHttpFields({cache: false});
  }));

  it('should exist', () => {
    expect(HalLink).to.exist;
  });

  describe('when creating a HalLink from an empty object', () => {
    beforeEach(() => {
      link = HalLink.fromObject({});
    });

    it('should have the "get" method as default', () => {
      expect(link.method).to.eq('get');
    });

    it('should have a null href', () => {
      expect(link.href).to.be.null;
    });

    it('should not be templated', () => {
      expect(link.templated).to.be.false;
    });

    it('should have an empty string as title', () => {
      expect(link.title).to.equal('');
    });
  });

  describe('when fetching a link that has a null href', () => {
    beforeEach(() => {
      link = new HalLink();
      link.href = null;
    });

    it('should return a promise that has null as its return value', () => {
      expect(link.$fetch()).to.eventually.be.null;
      $rootScope.$apply();
    });
  });

  describe('when the method of the link is "delete"', () => {
    beforeEach(() => {
      link = HalLink.fromObject({
        href: 'home',
        method: 'delete'
      });
    });

    it('should throw no error', () => {
      expect(() => link.$fetch()).not.to.throw(Error);
    });
  });

  describe('when using the link', () => {
    var response;
    var result;

    beforeEach(() => {
      link = HalLink.fromObject({
        href: '/api/link'
      });
      response = {
        _links: {},
        hello: 'world'
      };

      link.$fetch().then(val => result = val);
      $httpBackend.expectGET('/api/link').respond(200, response);
      $httpBackend.flush();
    });

    it('should return a promise that returns the given value', () => {
      expect(result.hello).to.eq(response.hello);
    });

    it('should not return a restangularized result', () => {
      expect(result.restangularized).to.not.be.ok;
    });

    it('should return a HalResource', () => {
      expect(result.$isHal).to.be.true;
    });

    it('should perform a GET request by default', () => {
      link.$fetch();
      $httpBackend.expectGET('/api/link').respond(200);
      $httpBackend.flush();
    });

    it('should pass parameters as query params to the request', () => {
      link.$fetch({
        hello: 'world'
      });
      $httpBackend.expectGET('/api/link?hello=world').respond(200);
      $httpBackend.flush();
    });

    it('should perform a POST request', () => {
      link.method = 'post';

      link.$fetch();
      $httpBackend.expectPOST('/api/link').respond(200);
      $httpBackend.flush();
    });

    it('should perform a PUT request', () => {
      link.method = 'put';

      link.$fetch();
      $httpBackend.expectPUT('/api/link').respond(200);
      $httpBackend.flush();
    });

    it('should perform a PATCH request', () => {
      link.method = 'patch';

      link.$fetch();
      $httpBackend.expectPATCH('/api/link').respond(200);
      $httpBackend.flush();
    });


    describe('when making the link callable', () => {
      var func;
      const runChecks = () => {
        it('should return a function that fetches the data', () => {
          func();

          $httpBackend.expectGET('/api/link').respond(200);
          $httpBackend.flush();
        });

        it('should pass the params to $fetch', () => {
          var $fetch = sinon.spy(link, '$fetch');
          func('hello');

          expect($fetch.calledWith('hello')).to.be.true;
        });
      };

      describe('when using the instance method', () => {
        beforeEach(() => {
          func = link.$callable();
        });
        runChecks();
      });

      describe('when using the static factory method', () => {
        beforeEach(() => {
          func = HalLink.callable(link);
          link = func.$link;
        });
        runChecks();
      });
    });
  });
});
