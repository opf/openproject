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

import {opApiModule} from '../../../../angular-modules';
import {WorkPackageResource} from './work-package-resource.service';
import {WorkPackageCacheService} from '../../../work-packages/work-package-cache.service';
import IHttpBackendService = angular.IHttpBackendService;
import SinonStub = Sinon.SinonStub;

describe('WorkPackageResource service', () => {
  var $httpBackend:IHttpBackendService;
  var WorkPackageResource;
  var wpCacheService:WorkPackageCacheService;

  beforeEach(angular.mock.module(opApiModule.name));
  beforeEach(angular.mock.inject(function (_$httpBackend_,
                                           _WorkPackageResource_,
                                           _wpCacheService_) {
    [$httpBackend, WorkPackageResource, wpCacheService] = _.toArray(arguments);
  }));

  it('should exist', () => {
    expect(WorkPackageResource).to.exist;
  });

  describe('when the resource was created', () => {
    var source:any;
    var resource:WorkPackageResource;
    var updateWorkPackageStub:SinonStub;

    beforeEach(() => {
      source = {
        _links: {
          activities: {
            href: 'activities'
          }
        }
      };
      resource = new WorkPackageResource(source);
      updateWorkPackageStub = sinon.stub(wpCacheService, 'updateWorkPackage');
    });

    afterEach(() => {
      updateWorkPackageStub.restore();
    });

    describe('when updating the activities', () => {
      beforeEach(() => {
        resource.updateActivities();

        $httpBackend
          .expectGET('activities', headers => headers.caching.enabled === false)
          .respond(200, {});
        $httpBackend.flush();
      });

      it('should update the work package cache', () => {
        expect(updateWorkPackageStub.calledWith(resource)).to.be.true;
      });
    });
  });
});

