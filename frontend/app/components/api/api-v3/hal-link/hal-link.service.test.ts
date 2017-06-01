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
import {HalRequestService} from '../hal-request/hal-request.service';

describe('HalLink service', () => {
  var $httpBackend:ng.IHttpBackendService;
  var $rootScope:any;
  var HalLink:any;
  var link:HalLink;

  beforeEach(angular.mock.module(opApiModule.name, opServicesModule.name));
  beforeEach(angular.mock.inject(function (_$httpBackend_:any,
                                           _$rootScope_:any,
                                           _HalLink_:any,
                                           halRequest:HalRequestService) {
    [$httpBackend, $rootScope, HalLink] = _.toArray(arguments);
    halRequest.defaultHeaders.caching.enabled = false;
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

  describe('when passing headers to $fetch', () => {
    beforeEach(() => {
      link = HalLink.fromObject({href: 'foobar'});
      link.$fetch({param: 'foo'}, {foo: 'bar'});
    });

    it('should send the headers', () => {
      $httpBackend.expectGET('foobar?param=foo', (headers:any) => headers.foo === 'bar').respond(200, {});
      $httpBackend.flush();
    });
  });

  describe('when using the link', () => {
    var response:any;
    var result:any;

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

    it('should return a HalResource', () => {
      expect(result.$isHal).to.be.true;
    });

    it('should perform a GET request by default', () => {
      link.$fetch();
      $httpBackend.expectGET('/api/link').respond(200, {});
      $httpBackend.flush();
    });

    it('should send the provided data', () => {
      const data = {hello: 'world'};
      link.method = 'post';

      link.$fetch(data);
      $httpBackend.expect('POST', '/api/link', data).respond(200, {});
      $httpBackend.flush();
    });

    it('should perform a POST request', () => {
      link.method = 'post';

      link.$fetch();
      $httpBackend.expectPOST('/api/link').respond(200, {});
      $httpBackend.flush();
    });

    it('should perform a PUT request', () => {
      link.method = 'put';

      link.$fetch();
      $httpBackend.expectPUT('/api/link').respond(200, {});
      $httpBackend.flush();
    });

    it('should perform a PATCH request', () => {
      link.method = 'patch';

      link.$fetch();
      $httpBackend.expectPATCH('/api/link').respond(200, {});
      $httpBackend.flush();
    });

    describe('when making the link callable', () => {
      var func:any;
      const runChecks = () => {
        it('should return a function that fetches the data', () => {
          func();

          $httpBackend.expectPOST('foo').respond(200, {});
          $httpBackend.flush();
        });

        it('should pass the params to $fetch', () => {
          var $fetch = sinon.spy(link, '$fetch');
          func('hello');

          expect($fetch.calledWith('hello')).to.be.true;
        });

        it('should have the href property of the link', () => {
          expect(func.href).to.equal(link.href);
        });

        it('should have the title property of the link', () => {
          expect(func.title).to.equal(link.title);
        });

        it('should have the method property of the link', () => {
          expect(func.method).to.equal(link.method);
        });

        it('should have the templated property of the link', () => {
          expect(func.templated).to.equal(link.templated);
        });
      };

      beforeEach(() => {
        link.href = 'foo';
        link.title = 'title';
        link.method = 'post';
        link.templated = true;
      });

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

    describe('when $preparing the link', () => {
      var func:any;

      beforeEach(() => {
        link.href = '/foo/bar/{user_id}';
        link.title = 'title';
        link.method = 'post';
        link.templated = true;
      });

      describe('when the link is NOT templated', () => {
        beforeEach(() => {
          link.templated = false;
        });
        it('should raise an exception', () => {
          expect(function() {
            link.$prepare({});
          }).to.throw;
        });
      });

      describe('when the link is templated', () => {
        beforeEach(() => {
          func = link.$prepare({ user_id: '1234' });
        });

        it('should return a function that fetches the data', () => {
          func();

          $httpBackend.expectPOST('/foo/bar/1234').respond(200, {});
          $httpBackend.flush();
        });

        it('should pass the params to $fetch', () => {
          var $fetch = sinon.spy(func.$link, '$fetch');
          func('hello');

          expect($fetch.calledWith('hello')).to.be.true;
        });

        it('should have the untemplated href property', () => {
          expect(func.href).to.equal('/foo/bar/1234');
        });

        it('should have the title property of the link', () => {
          expect(func.title).to.equal(link.title);
        });

        it('should have the method property of the link', () => {
          expect(func.method).to.equal(link.method);
        });

        it('should not be templated', () => {
          expect(func.templated).to.equal(false);
        });
      });
    });
  });
});
