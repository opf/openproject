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

/*jshint expr: true*/

describe('HALAPIResource', function() {

  var HALAPIResource, testPathHelper;
  beforeEach(module('openproject.api'));

  beforeEach(function() {
    testPathHelper = {
      apiV3: '/api/v3',
      appBasePath: ''
    };

    module(function($provide) {
      $provide.value('PathHelper', testPathHelper);
    });

    inject(function(_HALAPIResource_) {
      HALAPIResource = _HALAPIResource_;
    });
  });

  describe('setup', function() {
    var apiResource, resourceFunction;
    var workPackageUri = 'work_packages/1';

    beforeEach(inject(function($q) {
      apiResource = {
        fetch: $q.when(function() { return { id: workPackageId }; })
      };
    }));

    beforeEach(inject(function(HALAPIResource) {
      resourceFunction = sinon.stub(Hyperagent, 'Resource').returns(apiResource);
    }));

    afterEach(function() {
      resourceFunction.restore();
    });

    describe('with default (empty) base path', function() {
      beforeEach(inject(function() {
        HALAPIResource.setup(workPackageUri);
      }));

      it('makes an api setup call', function() {
        expect(resourceFunction).to.have.been.calledWith({
          url: "/api/v3/" + workPackageUri
        });
      });
    });

    describe('with custom appBasePath', function() {
      beforeEach(inject(function() {
        testPathHelper.appBasePath = '/whitelabel';

        HALAPIResource.setup(workPackageUri);
      }));

      it('makes an api setup call', function() {
        expect(resourceFunction).to.have.been.calledWith({
          url: "/whitelabel/api/v3/" + workPackageUri
        });
      });
    });

  });
});
