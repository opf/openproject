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

import {async, TestBed} from '@angular/core/testing';
import {OpenprojectHalModule} from 'core-app/modules/hal/openproject-hal.module';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {Injector} from '@angular/core';
import {States} from 'core-components/states.service';
import {TypeDmService} from 'core-app/modules/hal/dm-services/type-dm.service';
import {$stateToken, I18nToken} from 'core-app/angular4-transition-utils';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {NotificationsService} from 'core-components/common/notifications/notifications.service';
import {WorkPackageCreateService} from 'core-components/wp-new/wp-create.service';
import {ApiWorkPackagesService} from 'core-components/api/api-work-packages/api-work-packages.service';
import {WorkPackageNotificationService} from 'core-components/wp-edit/wp-notification.service';
import {SchemaCacheService} from 'core-components/schemas/schema-cache.service';
import {PathHelperService} from 'core-components/common/path-helper/path-helper.service';
import {WorkPackageCacheService} from 'core-components/work-packages/work-package-cache.service';
import {AttachmentCollectionResource} from 'core-app/modules/hal/resources/attachment-collection-resource';
import {SinonStub} from 'sinon';
import {LoadingIndicatorService} from 'core-components/common/loading-indicator/loading-indicator.service';
import {ConfigurationService} from 'core-components/common/config/configuration.service';

describe('WorkPackage', () => {
  let halResourceService:HalResourceService;
  let injector:Injector;
  let wpCacheService:WorkPackageCacheService;
  let notificationsService:NotificationsService;
  let wpNotificationsService:WorkPackageNotificationService;

  let source:any;
  let workPackage:WorkPackageResource;

  const createWorkPackage = () => {
    source = source || { id: 'new' };
    workPackage = halResourceService.createHalResourceOfType('WorkPackage', source);
  };

  beforeEach(async(() => {
    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      imports: [
        OpenprojectHalModule
      ],
      providers: [
        HalResourceService,
        States,
        TypeDmService,
        WorkPackageCacheService,
        NotificationsService,
        ConfigurationService,
        WorkPackageNotificationService,
        LoadingIndicatorService,
        PathHelperService,
        { provide: ApiWorkPackagesService, useValue: {} },
        { provide: WorkPackageCreateService, useValue: {} },
        { provide: $stateToken, useValue: {} },
        { provide: I18nToken, useValue: {} },
        { provide: SchemaCacheService, useValue: {} },
      ]
    })
      .compileComponents()
      .then(() => {
        halResourceService = TestBed.get(HalResourceService);
        injector = TestBed.get(Injector);
        wpCacheService = injector.get(WorkPackageCacheService);
        notificationsService = injector.get(NotificationsService);
        wpNotificationsService = injector.get(WorkPackageNotificationService);

        halResourceService.registerResource('WorkPackage', { cls: WorkPackageResource });
      });
  }));

  describe('when creating an empty work package', () => {
    beforeEach(createWorkPackage);

    it('should have an attachments property of type `AttachmentCollectionResource`', () => {
      expect(workPackage.attachments).to.be.instanceOf(AttachmentCollectionResource);
    });

    it('should return true for `isNew`', () => {
      expect(workPackage.isNew).to.be.true;
    });
  });

  describe('when retrieving `canAddAttachment`', () => {
    beforeEach(createWorkPackage);

    const expectValue = (value:any, prepare = () => angular.noop()) => {
      value = value.toString();

      beforeEach(prepare);
      it('should be ' + value, () => {
        (expect(workPackage.canAddAttachments).to.be as any)[value];
      });
    };

    describe('when the work package is new', () => {
      expectValue(true);
    });

    describe('when the work package is not new', () => {
      expectValue(false, () => {
        workPackage.$source.id = 420;
      });
    });

    describe('when the work work package has no `addAttachment` link and is not new', () => {
      expectValue(false, () => {
        workPackage.$source.id = 69;
        workPackage.$links.addAttachment = null as any;
      });
    });

    describe('when the work work package has an `addAttachment` link', () => {
      expectValue(true, () => {
        workPackage.$links.addAttachment = <any> angular.noop;
      });
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

  describe('when using uploadPendingAttachments', () => {
    let uploadAttachmentsStub:sinon.SinonStub;

    beforeEach(() => {
      workPackage.pendingAttachments.push({} as any, {} as any);
      uploadAttachmentsStub = sinon
        .stub(workPackage, 'uploadAttachments')
        .returns(Promise.resolve());
    });

    beforeEach(() => {
      workPackage.$source.id = 1234;
      workPackage.uploadPendingAttachments();
    });

    afterEach(() => {
      uploadAttachmentsStub.restore();
    })

    it('should call the uploadAttachments method with the pendingAttachments', () => {
      expect(uploadAttachmentsStub.calledWith([{}, {}])).to.be.true;
    });

    describe('when the upload succeeds', () => {
      it('should reset the pending attachments', () => {
        expect(workPackage.pendingAttachments).to.have.length(0);
      });
    });
  });

  describe('when using removeAttachment', () => {
    let file:any;
    let attachment:any;

    beforeEach(() => {
      file = {};
      attachment = {
        $isHal: true,
        'delete': sinon.stub()
      };

      createWorkPackage();
      workPackage.attachments.elements = [attachment];
      workPackage.pendingAttachments.push(file);
    });

    describe('when the attachment is a regular file', () => {
      it('should be removed from the pending attachments', () => {
        workPackage.removeAttachment(file);
        expect(workPackage.pendingAttachments).to.have.length(0);
      });
    });

    describe('when the attachment is an attachment resource', () => {
      let result = Promise.resolve();

      beforeEach(() => {
        attachment.delete.returns(result);
        sinon.stub(workPackage, 'updateAttachments');
      });

      it('should call its delete method', (done) => {
        workPackage.removeAttachment(attachment).then(() => {
          expect(attachment.delete.calledOnce).to.be.true;
          done();
        });
      });

      describe('when the deletion gets resolved', () => {
        it('should call updateAttachments()', (done) => {
          workPackage.removeAttachment(attachment).then(() => {
            expect((workPackage.updateAttachments as SinonStub).calledOnce).to.be.true;
            done();
          });
        });
      });

      describe('when an error occurs', () => {
        var error:any;
        let errorStub:SinonStub;

        beforeEach(() => {
          error = { foo: 'bar' };
          attachment.delete.returns(Promise.reject(error));
          errorStub = sinon.stub(wpNotificationsService, 'handleErrorResponse');
        });

        afterEach(() => {
          errorStub.restore();
        });

        it('should call the handleErrorResponse notification', (done) => {
          workPackage.removeAttachment(attachment).then(() => {
            expect(errorStub, 'Calls handleErrorResponse').to.have.been.called;
            done();
          });
        });

        it('should not remove the attachment from the elements array', (done) => {
          workPackage.removeAttachment(attachment).then(() => {
            expect(workPackage.attachments.elements).to.have.length(1);
            done();
          });
        });
      });
    });
  });

});
