//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { Injector } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { NotificationsService } from 'core-app/modules/common/notifications/notifications.service';
import { PathHelperService } from 'core-app/modules/common/path-helper/path-helper.service';
import { OpenprojectHalModule } from 'core-app/modules/hal/openproject-hal.module';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { HalResourceService } from 'core-app/modules/hal/services/hal-resource.service';
import { OpenProjectFileUploadService } from 'core-components/api/op-file-upload/op-file-upload.service';
import { OpenProjectDirectFileUploadService } from "core-components/api/op-file-upload/op-direct-file-upload.service";
import { SchemaCacheService } from 'core-components/schemas/schema-cache.service';
import { States } from 'core-components/states.service';
import { HalResourceNotificationService } from "core-app/modules/hal/services/hal-resource-notification.service";
import { take, takeWhile } from 'rxjs/operators';
import { WorkPackagesActivityService } from "core-components/wp-single-view-tabs/activity-panel/wp-activity.service";
import { TimezoneService } from "core-components/datetime/timezone.service";
import { ConfigurationService } from "core-app/modules/common/config/configuration.service";
import { WorkPackageNotificationService } from "core-app/modules/work_packages/notifications/work-package-notification.service";
import { WorkPackageCache } from "core-app/modules/apiv3/endpoints/work_packages/work-package.cache";

describe('WorkPackageCache', () => {
  let injector:Injector;
  let states:States;
  let workPackageCache:WorkPackageCache;
  let schemaCacheService:SchemaCacheService;
  let dummyWorkPackages:WorkPackageResource[] = [];

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [
        OpenprojectHalModule,
      ],
      providers: [
        States,
        HalResourceService,
        TimezoneService,
        WorkPackagesActivityService,
        SchemaCacheService,
        PathHelperService,
        { provide: ConfigurationService, useValue: {} },
        { provide: I18nService, useValue: { t: (...args:any[]) => 'translation' } },
        { provide: WorkPackageResource, useValue: {} },
        { provide: NotificationsService, useValue: {} },
        { provide: HalResourceNotificationService, useValue: { handleRawError: () => false } },
        { provide: WorkPackageNotificationService, useValue: {} },
        { provide: OpenProjectFileUploadService, useValue: {} },
        { provide: OpenProjectDirectFileUploadService, useValue: {} },
      ]
    });

    injector = TestBed.inject(Injector);
    states = TestBed.inject(States);
    schemaCacheService = TestBed.inject(SchemaCacheService);
    workPackageCache = new WorkPackageCache(injector, states.workPackages);

    // sinon.stub(schemaCacheService, 'ensureLoaded').returns(Promise.resolve(true));
    spyOn(schemaCacheService, 'ensureLoaded').and.returnValue(Promise.resolve(true as any));


    const workPackage1 = new WorkPackageResource(
      injector,
      {
        id: '1',
        _links: {
          self: ''
        }
      },
      true,
      (wp:WorkPackageResource) => undefined,
      'WorkPackage'
    );

    dummyWorkPackages = [workPackage1 as any];
  });

  it('returns a work package after the list has been initialized', function (done:any) {
    workPackageCache.state('1').values$()
      .pipe(
        take(1)
      )
      .subscribe((wp:WorkPackageResource) => {
        expect(wp.id!).toEqual('1');
        done();
      });

    workPackageCache.updateWorkPackageList(dummyWorkPackages);
  });

  it('should return/stream a work package every time it gets updated', (done:any) => {
    let count = 0;

    workPackageCache.state('1').values$()
      .pipe(
        takeWhile((wp) => count < 2)
      )
      .subscribe((wp:WorkPackageResource) => {
        expect(wp.id!).toEqual('1');

        count += 1;
        if (count === 2) {
          done();
        }
      });

    workPackageCache.updateWorkPackageList([dummyWorkPackages[0]], false);
    workPackageCache.updateWorkPackageList([dummyWorkPackages[0]], false);
    workPackageCache.updateWorkPackageList([dummyWorkPackages[0]], false);
  });

});
