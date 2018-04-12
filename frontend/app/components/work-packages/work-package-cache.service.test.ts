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

import {TestBed} from '@angular/core/testing';

require('core-app/angular4-test-setup');

import {SchemaCacheService} from 'core-components/schemas/schema-cache.service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageCacheService} from 'core-components/work-packages/work-package-cache.service';
import {ApiWorkPackagesService} from 'core-components/api/api-work-packages/api-work-packages.service';
import {WorkPackageNotificationService} from 'core-components/wp-edit/wp-notification.service';
import {States} from 'core-components/states.service';
import {take, takeWhile} from 'rxjs/operators';
import {Injector} from '@angular/core';

describe('WorkPackageCacheService', () => {
  let injector:Injector;
  let wpCacheService:WorkPackageCacheService;
  let schemaCacheService:SchemaCacheService;
  let dummyWorkPackages:WorkPackageResource[] = [];

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        States,
        WorkPackageCacheService,
        SchemaCacheService,
        { provide: ApiWorkPackagesService, useValue: {}},
        { provide: WorkPackageResource, useValue: {}},
        { provide: WorkPackageNotificationService, useValue: {}}
      ]
    });

    injector = TestBed.get(Injector);
    wpCacheService = TestBed.get(WorkPackageCacheService);
    schemaCacheService = TestBed.get(SchemaCacheService);

    sinon.stub(schemaCacheService, 'ensureLoaded').returns(Promise.resolve(true));

    const workPackage1 = new WorkPackageResource(
      injector,
      {
        id: '1',
        _links: {
          self: ""
        }
      },
      true,
      (wp:WorkPackageResource) => undefined
    );

    dummyWorkPackages = [workPackage1];
  });

  it('returns a work package after the list has been initialized', function(done:any) {
    wpCacheService.loadWorkPackage('1').values$()
      .pipe(
        take(1)
      )
      .subscribe((wp:WorkPackageResource) => {
        expect(wp.id).to.eq('1');
        done();
      });

    wpCacheService.updateWorkPackageList(dummyWorkPackages as WorkPackageResource[]);
  });

  it('should return/stream a work package every time it gets updated', (done:any) => {
    let count = 0;

    wpCacheService.loadWorkPackage('1').values$()
      .pipe(
        takeWhile((wp) => count < 2)
      )
      .subscribe((wp:WorkPackageResource) => {
        expect(wp.id).to.eq('1');

        count += 1;
        if (count === 2) {
          done();
        }
      });

    wpCacheService.updateWorkPackageList([dummyWorkPackages[0]] as WorkPackageResource[]);
    wpCacheService.updateWorkPackageList([dummyWorkPackages[0]] as WorkPackageResource[]);
    wpCacheService.updateWorkPackageList([dummyWorkPackages[0]] as WorkPackageResource[]);
  });
});
