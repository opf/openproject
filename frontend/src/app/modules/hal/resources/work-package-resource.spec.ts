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

import { TestBed, waitForAsync } from '@angular/core/testing';
import { OpenprojectHalModule } from 'core-app/modules/hal/openproject-hal.module';
import { HalResourceService } from 'core-app/modules/hal/services/hal-resource.service';
import { Injector } from '@angular/core';
import { States } from 'core-components/states.service';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { NotificationsService } from 'core-app/modules/common/notifications/notifications.service';
import { HalResourceNotificationService } from "core-app/modules/hal/services/hal-resource-notification.service";
import { SchemaCacheService } from 'core-components/schemas/schema-cache.service';
import { PathHelperService } from 'core-app/modules/common/path-helper/path-helper.service';
import { AttachmentCollectionResource } from 'core-app/modules/hal/resources/attachment-collection-resource';
import { LoadingIndicatorService } from 'core-app/modules/common/loading-indicator/loading-indicator.service';
import { ConfigurationService } from 'core-app/modules/common/config/configuration.service';
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { StateService } from "@uirouter/core";
import { OpenProjectFileUploadService } from "core-components/api/op-file-upload/op-file-upload.service";
import { OpenProjectDirectFileUploadService } from "core-components/api/op-file-upload/op-direct-file-upload.service";
import { WorkPackageCreateService } from 'core-app/components/wp-new/wp-create.service';
import { WorkPackageNotificationService } from "core-app/modules/work_packages/notifications/work-package-notification.service";
import { WorkPackagesActivityService } from "core-components/wp-single-view-tabs/activity-panel/wp-activity.service";
import { TimezoneService } from "core-components/datetime/timezone.service";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";

describe('WorkPackage', () => {
  let halResourceService:HalResourceService;
  let injector:Injector;
  let notificationsService:NotificationsService;
  let halResourceNotification:HalResourceNotificationService;

  let source:any;
  let workPackage:WorkPackageResource;

  const createWorkPackage = () => {
    source = source || { id: 'new' };
    workPackage = halResourceService.createHalResourceOfType('WorkPackage', { ...source });
  };

  beforeEach(waitForAsync(() => {
    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      imports: [
        OpenprojectHalModule
      ],
      providers: [
        HalResourceService,
        States,
        TimezoneService,
        WorkPackagesActivityService,
        NotificationsService,
        ConfigurationService,
        OpenProjectFileUploadService,
        OpenProjectDirectFileUploadService,
        LoadingIndicatorService,
        PathHelperService,
        I18nService,
        APIV3Service,
        { provide: HalResourceNotificationService, useValue: { handleRawError: () => false } },
        { provide: WorkPackageNotificationService, useValue: {} as any },
        { provide: WorkPackageCreateService, useValue: {} },
        { provide: StateService, useValue: {} },
        { provide: SchemaCacheService, useValue: {} },
      ]
    })
      .compileComponents()
      .then(() => {
        halResourceService = TestBed.get(HalResourceService);
        injector = TestBed.get(Injector);
        notificationsService = injector.get(NotificationsService);
        halResourceNotification = injector.get(HalResourceNotificationService);

        halResourceService.registerResource('WorkPackage', { cls: WorkPackageResource });
      });
  }));

  describe('when creating an empty work package', () => {
    beforeEach(createWorkPackage);

    it('should have an attachments property of type `AttachmentCollectionResource`', () => {
      expect(workPackage.attachments).toEqual(jasmine.any(AttachmentCollectionResource));
    });

    it('should return true for `isNew`', () => {
      expect(workPackage.isNew).toBeTruthy();
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

    it('when the work work package has no `addAttachment` link and is not new', () => {
      workPackage.$source.id = 69;
      workPackage.$links.addAttachment = null as any;
      expect(workPackage.canAddAttachments).toEqual(false);
    });

    it('when the work work package has an `addAttachment` link', () => {
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
          activities: { href: 'activities' }
        },
        isNew: true
      };
      createWorkPackage();
    });
  });

  describe('when using removeAttachment', () => {
    let file:any;
    let attachment:any;
    let result:any;

    beforeEach(() => {
      file = {};
      attachment = {
        $isHal: true,
        'delete': () => undefined
      };

      createWorkPackage();
      workPackage.attachments.elements = [attachment];
    });

    describe('when the attachment is an attachment resource', () => {
      beforeEach(() => {
        attachment.delete = jasmine.createSpy('delete').and.returnValue(Promise.resolve());
        spyOn(workPackage, 'updateAttachments');
      });

      it('should call its delete method', (done) => {
        workPackage.removeAttachment(attachment).then(() => {
          expect(attachment.delete).toHaveBeenCalled();
          done();
        });
      });

      describe('when the deletion gets resolved', () => {
        it('should call updateAttachments()', (done) => {
          workPackage.removeAttachment(attachment).then(() => {
            expect(workPackage.updateAttachments).toHaveBeenCalled();
            done();
          });
        });
      });

      describe('when an error occurs', () => {
        let errorStub:jasmine.Spy;

        beforeEach(() => {
          attachment.delete = jasmine.createSpy('delete')
            .and.returnValue(Promise.reject({ foo: 'bar' }));

          errorStub = spyOn(halResourceNotification, 'handleRawError');
        });

        it('should call the handleRawError notification', (done) => {
          workPackage.removeAttachment(attachment).then(() => {
            expect(errorStub).toHaveBeenCalled();
            done();
          });
        });

        it('should not remove the attachment from the elements array', (done) => {
          workPackage.removeAttachment(attachment).then(() => {
            expect(workPackage.attachments.elements.length).toEqual(1);
            done();
          });
        });
      });
    });
  });

});
