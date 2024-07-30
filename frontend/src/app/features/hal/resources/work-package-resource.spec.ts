//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { TestBed, waitForAsync } from '@angular/core/testing';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { Injector } from '@angular/core';
import { States } from 'core-app/core/states/states.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { StateService } from '@uirouter/core';
import { WorkPackageCreateService } from 'core-app/features/work-packages/components/wp-new/wp-create.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { WorkPackagesActivityService } from 'core-app/features/work-packages/components/wp-single-view-tabs/activity-panel/wp-activity.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { AttachmentCollectionResource } from 'core-app/features/hal/resources/attachment-collection-resource';
import { OpenprojectHalModule } from 'core-app/features/hal/openproject-hal.module';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { of } from 'rxjs';
import { HttpClientTestingModule } from '@angular/common/http/testing';

describe('WorkPackage', () => {
  let halResourceService:HalResourceService;
  let injector:Injector;
  let halResourceNotification:HalResourceNotificationService;

  let source:any;
  let workPackage:WorkPackageResource;

  const createWorkPackage = () => {
    source = source || { id: 'new' };
    workPackage = halResourceService.createHalResourceOfType('WorkPackage', { ...source });
  };

  const WeekdayServiceStub = {
    loadWeekdays: () => of(true),
  };

  beforeEach(waitForAsync(() => {
    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      imports: [
        OpenprojectHalModule,
        HttpClientTestingModule,
      ],
      providers: [
        HalResourceService,
        States,
        TimezoneService,
        WorkPackagesActivityService,
        { provide: WeekdayService, useValue: WeekdayServiceStub },
        ConfigurationService,
        LoadingIndicatorService,
        PathHelperService,
        I18nService,
        ApiV3Service,
        { provide: HalResourceNotificationService, useValue: { handleRawError: () => false } },
        { provide: WorkPackageNotificationService, useValue: {} as any },
        { provide: WorkPackageCreateService, useValue: {} },
        { provide: StateService, useValue: {} },
        { provide: SchemaCacheService, useValue: {} },
      ],
    })
      .compileComponents()
      .then(() => {
        halResourceService = TestBed.inject(HalResourceService);
        injector = TestBed.inject(Injector);
        halResourceNotification = injector.get(HalResourceNotificationService);

        halResourceService.registerResource('WorkPackage', { cls: WorkPackageResource });
      });
  }));

  describe('when creating an empty work package', () => {
    beforeEach(createWorkPackage);

    it('should have an attachments property of type `AttachmentCollectionResource`', () => {
      expect(workPackage.attachments).toEqual(jasmine.any(AttachmentCollectionResource));
    });

    it('should return true for `isNewResource`', () => {
      expect(isNewResource(workPackage)).toBeTruthy();
    });
  });

  describe('when retrieving `canAddAttachment`', () => {
    beforeEach(createWorkPackage);

    it('should be true for new work packages', () => {
      expect(workPackage.canAddAttachments).toEqual(true);
    });

    it('when work package is not new', () => {
      workPackage.$source.id = 420;
      expect(workPackage.canAddAttachments).toEqual(false);
    });

    it('when the work package has no `addAttachment` link and is not new', () => {
      workPackage.$source.id = 69;
      workPackage.$links.addAttachment = null as any;
      expect(workPackage.canAddAttachments).toEqual(false);
    });

    it('when the work package has an `addAttachment` link', () => {
      workPackage.$links.addAttachment = <any> _.noop;
      expect(workPackage.canAddAttachments).toEqual(true);
    });
  });

  describe('when a work package is created with attachments and activities', () => {
    beforeEach(() => {
      source = {
        _links: {
          schema: { _type: 'Schema', href: 'schema' },
          attachments: { href: 'attachments' },
          activities: { href: 'activities' },
        },
        isNew: true,
      };
      createWorkPackage();
    });
  });
});
