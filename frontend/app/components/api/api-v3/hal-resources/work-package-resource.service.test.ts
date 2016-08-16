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
import {WorkPackageResourceInterface} from './work-package-resource.service';
import {WorkPackageCacheService} from '../../../work-packages/work-package-cache.service';
import IHttpBackendService = angular.IHttpBackendService;
import SinonStub = Sinon.SinonStub;
import IQService = angular.IQService;
import IRootScopeService = angular.IRootScopeService;
import IPromise = angular.IPromise;

describe('WorkPackageResource service', () => {
  var $httpBackend: IHttpBackendService;
  var $rootScope: IRootScopeService;
  var $q: IQService;
  var WorkPackageResource;
  var AttachmentCollectionResource;
  var wpCacheService: WorkPackageCacheService;
  var NotificationsService: any;
  var wpNotificationsService: any;

  beforeEach(angular.mock.module(opApiModule.name));
  beforeEach(angular.mock.inject(function (_$httpBackend_,
                                           _$rootScope_,
                                           _$q_,
                                           _WorkPackageResource_,
                                           _AttachmentCollectionResource_,
                                           _wpCacheService_,
                                           _NotificationsService_,
                                           _wpNotificationsService_) {
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

  describe('when the work package is created', () => {
    var source: any;
    var workPackage: WorkPackageResourceInterface;

    const createWorkPackage = () => {
      workPackage = new WorkPackageResource(source);
    };

    describe('when creating an empty work package', () => {
      beforeEach(() => {
        source = {};
        createWorkPackage();
      });

      it('should have an attachments property of type `AttachmentCollectionResource`', () => {
        expect(workPackage.attachments).to.be.instanceOf(AttachmentCollectionResource);
      });

      it('should return true for `isNew`', () => {
        expect(workPackage.isNew).to.be.true;
      });
    });

    describe('when a work package is created with attachments and activities', () => {
      const expectUncachedRequest = href => {
        $httpBackend
          .expectGET(href, headers => headers.caching.enabled === false)
          .respond(200, {_links: {self: {href}}});
      };

      beforeEach(() => {
        source = {
          _links: {
            attachments: {
              href: 'attachments'
            },
            activities: {
              href: 'activities'
            }
          }
        };
        createWorkPackage();
      });

      describe('when adding multiple attachments to the work package', () => {
        var file: any = {};
        var files: any[] = [file, file];
        var uploadFilesDeferred;
        var uploadAttachmentsPromise;
        var attachmentsUploadStub;
        var uploadNotificationStub;

        beforeEach(() => {
          uploadFilesDeferred = $q.defer();
          const uploadResult = {uploads: [uploadFilesDeferred.promise], upload: uploadFilesDeferred.promise};
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
          var notificationStub;
          var error = 'err';

          beforeEach(() => {
            uploadFilesDeferred.reject(error);
            notificationStub = sinon.stub(wpNotificationsService, 'handleErrorResponse');
            $rootScope.$apply();
          });

          it('should call the error response notification', () => {
            expect(notificationStub.calledWith(error, workPackage)).to.be.true;
          });
        });

        describe('when the upload succeeds', () => {
          var removeStub;

          beforeEach(() => {
            uploadFilesDeferred.resolve();
            removeStub = sinon.stub(NotificationsService, 'remove');

            expectUncachedRequest('activities');
            expectUncachedRequest('attachments');
            $httpBackend.flush();
            $rootScope.$apply();
          });

          it('should remove the upload notification', angular.mock.inject($timeout => {
            $timeout.flush();
            expect(removeStub.calledOnce).to.be.true;
          }));

          it('should return an attachment collection resource promise', () => {
            expect(uploadAttachmentsPromise).to.eventually.have.property('$href', 'attachments');
            $rootScope.$apply();
          });
        });
      });

      describe('when updating multiple linked resources', () => {
        var updateWorkPackageStub: SinonStub;
        var promise: any;

        const testWpCacheUpdateWith = (prepare, ...urls) => {
          beforeEach(() => {
            prepare();
            urls.forEach(expectUncachedRequest);
            $httpBackend.flush();
          });

          it('should update the work package cache', () => {
            expect(updateWorkPackageStub.calledWith(workPackage)).to.be.true;
          });
        };

        const testLinkedResource = href => {
          it('should return a promise that returns the ' + href, () => {
            expect(promise).to.eventually.have.property('$href', href);
          });
        };

        beforeEach(() => {
          updateWorkPackageStub = sinon.stub(wpCacheService, 'updateWorkPackage');
        });

        afterEach(() => {
          $rootScope.$apply();
          updateWorkPackageStub.restore();
        });

        describe('when updating the activities', () => {
          testWpCacheUpdateWith(() => {
            promise = workPackage.updateActivities();
          }, 'activities');

          testLinkedResource('activities');
        });

        describe('when updating the attachments', () => {
          testWpCacheUpdateWith(() => {
            promise = workPackage.updateAttachments();
          }, 'activities', 'attachments');

          testLinkedResource('attachments');
        });
      });
    });
  });
})
;

