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
import {WorkPackageCacheService} from '../../../work-packages/work-package-cache.service';
import IHttpBackendService = angular.IHttpBackendService;
import IQService = angular.IQService;
import IRootScopeService = angular.IRootScopeService;
import IPromise = angular.IPromise;

describe('WorkPackageResource service', () => {
  var $httpBackend: IHttpBackendService;
  var $rootScope: IRootScopeService;
  var $q: IQService;
  var WorkPackageResource:any;
  var AttachmentCollectionResource:any;
  var wpCacheService: WorkPackageCacheService;
  var NotificationsService: any;
  var wpNotificationsService: any;

  var source: any;
  var workPackage: any;

  const createWorkPackage = () => {
    source = source || { id: 'new' };
    workPackage = new WorkPackageResource(source);
  };

  const expectUncachedRequest = (href:string) => {
    $httpBackend
      .expectGET(href, (headers:any) => headers.caching.enabled === false)
      .respond(200, {_links: {self: {href}}});
  };

  const expectUncachedRequests = (...urls:string[]) => {
    urls.forEach(expectUncachedRequest);
    $httpBackend.flush();
  };

  beforeEach(angular.mock.module(opApiModule.name));
  beforeEach(angular.mock.inject(function (_$httpBackend_:any,
                                           _$rootScope_:any,
                                           _$q_:any,
                                           _WorkPackageResource_:any,
                                           _AttachmentCollectionResource_:any,
                                           _wpCacheService_:any,
                                           _NotificationsService_:any,
                                           _wpNotificationsService_:any) {
    [
      $httpBackend,
      $rootScope,
      $q,
      WorkPackageResource,
      AttachmentCollectionResource,
      wpCacheService,
      NotificationsService,
      wpNotificationsService
    ] = _.toArray(arguments);
  }));

  it('should exist', () => {
    expect(WorkPackageResource).to.exist;
  });

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

    const expectValue = (value:any, prepare = angular.noop) => {
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
        workPackage.id = 420;
      });
    });

    describe('when the work work package has no `addAttachment` link and is not new', () => {
      expectValue(false, () => {
        workPackage.id = 69;
        workPackage.$links.addAttachment = null;
      });
    });

    describe('when the work work package has an `addAttachment` link', () => {
      expectValue(true, () => {
        workPackage.$links.addAttachment = <any> angular.noop;
      });
    });
  });

  describe('when updating multiple linked resources', () => {
    var updateWorkPackageStub: sinon.SinonStub;
    var result:Promise<any>;

    const expectCacheUpdate = () => {
      it('should update the work package cache', () => {
        result.then(() => {
          expect(updateWorkPackageStub.calledWith(workPackage)).to.be.true;
        });
      });
    };

    beforeEach(() => {
      updateWorkPackageStub = sinon.stub(wpCacheService, 'updateWorkPackage');
    });

    afterEach(() => {
      $rootScope.$apply();
      updateWorkPackageStub.restore();
    });

    describe('when the resources are properties of the work package', () => {
      const testResultIsResource = (href:string, prepare:any) => {
        beforeEach(prepare);
        expectCacheUpdate();

        it('should be a promise with a resource where the $href  is ' + href, () => {
          expect(result).to.eventually.have.property('$href', href);
        });
      };

      beforeEach(() => {
        source = {
          _links: {
            schema: { _type: 'Schema', href: 'schema' },
            attachments: { href: 'attachmentsHref' },
            activities: { href: 'activitiesHref' }
          }
        };
        createWorkPackage();
      });

      describe('when updating the properties using updateLinkedResources()', () => {
        var results:any;

        beforeEach(() => {
          results = workPackage.updateLinkedResources('attachments', 'activities');
          expectUncachedRequests('attachmentsHref', 'activitiesHref');
        });

        it('should return a result, that has the same properties as the updated ones', () => {
          expect(results).to.eventually.be.fulfilled.then(results => {
            expect(Object.keys(results)).to.have.members(['attachments', 'activities']);
          });
        });

        testResultIsResource('attachmentsHref', () => {
          results.then((results:any) => result = $q.when(results.attachments));
        });

        testResultIsResource('activitiesHref', () => {
          results.then((results:any) => result = $q.when(results.activities));
        });
      });

      describe('when updating the activities', () => {
        testResultIsResource('activitiesHref', () => {
          result = workPackage.updateActivities();
          expectUncachedRequests('activitiesHref');
        });
      });

      describe('when updating the attachments', () => {
        testResultIsResource('attachmentsHref', () => {
          result = workPackage.updateAttachments();
          expectUncachedRequests('activitiesHref', 'attachmentsHref');
        });
      });
    });

    describe('when the linked resource are not properties of the work package', () => {
      const expectRejectedWithCacheUpdate = (prepare:any) => {
        beforeEach(prepare);

        it('should return a rejected promise', () => {
          expect(result).to.eventually.be.rejected;
        });

        expectCacheUpdate();
      };

      beforeEach(() => {
        source = {};
        createWorkPackage();
      });

      describe('when using updateLinkedResources', () => {
        expectRejectedWithCacheUpdate(() => {
          result = workPackage.updateLinkedResources('attachments', 'activities');
        });
      });

      describe('when using updateActivities', () => {
        expectRejectedWithCacheUpdate(() => {
          result = workPackage.updateActivities();
        });
      });

      describe('when using updateAttachments', () => {
        expectRejectedWithCacheUpdate(() => {
          result = workPackage.updateAttachments();
        });
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

    describe('when adding multiple attachments to the work package', () => {
      var file: any = {};
      var files: any[] = [file, file];
      var uploadFilesDeferred:any;
      var uploadAttachmentsPromise:any;
      var attachmentsUploadStub:any;
      var uploadNotificationStub:any;

      beforeEach(() => {
        uploadFilesDeferred = $q.defer();
        const uploadResult = {
          uploads: [uploadFilesDeferred.promise],
          finished: uploadFilesDeferred.promise
        };
        attachmentsUploadStub = sinon.stub(workPackage.attachments, 'upload').returns(uploadResult);
        uploadNotificationStub = sinon.stub(NotificationsService, 'addWorkPackageUpload');

        uploadAttachmentsPromise = workPackage.uploadAttachments(files);
      });

      it('should call the upload method of the attachment collection resource', () => {
        expect(attachmentsUploadStub.calledWith(files)).to.be.true;
      });

      it('should add an upload notification', () => {
        expect(uploadNotificationStub.calledOnce).to.be.true;
      });

      describe('when the upload fails', () => {
        var notificationStub:any;
        var error = 'err';

        beforeEach(() => {
          uploadFilesDeferred.reject(error);
          notificationStub = sinon.stub(wpNotificationsService, 'handleRawError');
          $rootScope.$apply();
        });

        it('should call the error response notification', () => {
          expect(notificationStub.calledWith(error, workPackage)).to.be.true;
        });
      });

      describe('when the upload succeeds', () => {
        var removeStub:any;
        var updateWorkPackageStub:any;

        beforeEach(() => {
          updateWorkPackageStub = sinon.stub(wpCacheService, 'updateWorkPackage');
          uploadFilesDeferred.resolve();
          removeStub = sinon.stub(NotificationsService, 'remove');

          expectUncachedRequest('activities');
          expectUncachedRequest('attachments');
          $httpBackend
            .when('GET', 'schema')
            .respond(200, {_links: {self: 'schema'}});
          $httpBackend.flush();
          $rootScope.$apply();
        });

        it('should remove the upload notification', angular.mock.inject(($timeout:ng.ITimeoutService) => {
          $timeout.flush();
          expect(removeStub.calledOnce).to.be.true;
        }));

        it('should return an attachment collection resource promise', () => {
          expect(uploadAttachmentsPromise).to.eventually.have.property('$href', 'attachments');
          $rootScope.$apply();
        });

        afterEach(() => {
          updateWorkPackageStub.restore();
          removeStub.restore();
        });
      });
    });

    describe('when using uploadPendingAttachments', () => {
      var uploadAttachmentsStub: sinon.SinonStub;

      beforeEach(() => {
        workPackage.pendingAttachments.push({}, {});
        uploadAttachmentsStub = sinon
          .stub(workPackage, 'uploadAttachments')
          .returns($q.when());
      });

      beforeEach(() => {
        workPackage.isNew = false;
        workPackage.uploadPendingAttachments();
      });

      it('should call the uploadAttachments method with the pendingAttachments', () => {
        expect(uploadAttachmentsStub.calledWith([{},{}])).to.be.true;
      });

      describe('when the upload succeeds', () => {
        beforeEach(() => {
          $rootScope.$apply();
        });

        it('should reset the pending attachments', () => {
          expect(workPackage.pendingAttachments).to.have.length(0);
        });
      });
    });
  });

  describe('when using removeAttachment', () => {
    var file:any;
    var attachment:any;

    beforeEach(() => {
      file = {};
      attachment = {
        $isHal: true,
        'delete': sinon.stub()
      };

      createWorkPackage();
      workPackage.attachments = {elements: [attachment]};
      workPackage.pendingAttachments.push(file);
    });

    describe('when the attachment is a regular file', () => {
      beforeEach(() => {
        workPackage.removeAttachment(file);
      });

      it('should be removed from the pending attachments', () => {
        expect(workPackage.pendingAttachments).to.have.length(0);
      });
    });

    describe('when the attachment is an attachment resource', () => {
      var deletion:any;

      beforeEach(() => {
        deletion = $q.defer();
        attachment.delete.returns(deletion.promise);
        sinon.stub(workPackage, 'updateAttachments');

        workPackage.removeAttachment(attachment);
      });

      it('should call its delete method', () => {
        expect(attachment.delete.calledOnce).to.be.true;
      });

      describe('when the deletion gets resolved', () => {
        beforeEach(() => {
          deletion.resolve();
          $rootScope.$apply();
        });

        it('should call updateAttachments()', () => {
          expect(workPackage.updateAttachments.calledOnce).to.be.true;
        });
      });

      describe('when an error occurs', () => {
        var error:any;

        beforeEach(() => {
          error = {foo: 'bar'};
          sinon.stub(wpNotificationsService, 'handleErrorResponse');
          deletion.reject(error);
          $rootScope.$apply();
        });

        it('should call the handleErrorResponse notification', () => {
          const calledWithErrorAndWorkPackage = wpNotificationsService
            .handleErrorResponse
            .calledWith(error, workPackage);

          expect(calledWithErrorAndWorkPackage).to.be.true;
        });

        it('should not remove the attachment from the elements array', () => {
          expect(workPackage.attachments.elements).to.have.length(1);
        });
      });
    });
  });
});
