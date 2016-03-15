// -- copyright
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
// ++

describe('apiV3 service', () => {
  var apiV3:restangular.IService;
  var $httpBackend:ng.IHttpBackendService;

  beforeEach(angular.mock.module('openproject.api'));
  beforeEach(angular.mock.module('openproject.services'));

  beforeEach(angular.mock.inject((_apiV3_, _$httpBackend_) => {
    apiV3 = _apiV3_;
    $httpBackend = _$httpBackend_;

    apiV3.setBaseUrl('/base');
  }));

  it('should exist', () => {
    expect(apiV3).to.exist;
  });

  describe('when after requesting a resource', () => {
    var promise;

    beforeEach(() => {
      promise = apiV3.one('resource').get();
      $httpBackend.expectGET('/base/resource').respond(200, {
        _links: {}
      });
    });

    it('should not be restangularized', () => {
      expect(promise).to.eventually.be.fulfilled.then(resource => {
        expect(resource.restangularized).to.not.be.ok;
      });
      $httpBackend.flush();
    });

    it('should be transformed', () => {
      expect(promise).to.eventually.be.fulfilled.then(resource => {
        expect(resource.$isHal).to.be.true;
      });
      $httpBackend.flush();
    });

    it('should not have a restangularized $source', () => {
      expect(promise).to.be.eventually.fulfilled.then(resource => {
        expect(resource.$source.restangularized).to.not.be.ok;
      });
      $httpBackend.flush();
    });

    it('should have a _plain property', done => {
      apiV3.addResponseInterceptor(data => {
        expect(data._plain).to.exist;
        done();
        return data;
      });
      $httpBackend.flush();
    });
  });
});
