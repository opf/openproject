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

  var source: any;
  var workPackage: WorkPackageResourceInterface;

  const createWorkPackage = () => {
    workPackage = new WorkPackageResource(source);
  };

  const expectUncachedRequest = href => {
    $httpBackend
      .expectGET(href, headers => headers.caching.enabled === false)
      .respond(200, {_links: {self: {href}}});
  };

  const expectUncachedRequests = (...urls) => {
    urls.forEach(expectUncachedRequest);
    $httpBackend.flush();
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

  describe('when updating multiple linked resources', () => {
    var updateWorkPackageStub: SinonStub;
    var result;

    const expectCacheUpdate = () => {
      it('should update the work package cache', () => {
        expect(updateWorkPackageStub.calledWith(workPackage)).to.be.true;
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
      const testResultIsResource = (href, prepare) => {
        beforeEach(prepare);
        expectCacheUpdate();

        it('should be a promise with a resource where the $href  is ' + href, () => {
          expect(result).to.eventually.have.property('$href', href);
        });
      };

      beforeEach(() => {
        source = {
          _links: {
            attachments: {href: 'attachmentsHref'},
            activities: {href: 'activitiesHref'}
          }
        };
        createWorkPackage();
      });

      describe('when updating the properties using updateLinkedResources()', () => {
        var results;

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
          results.then(results => result = $q.when(results.attachments));
        });

        testResultIsResource('activitiesHref', () => {
          results.then(results => result = $q.when(results.activities));
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
      const expectRejectedWithCacheUpdate = prepare => {
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
        const uploadResult = {
          uploads: [uploadFilesDeferred.promise],
          upload: uploadFilesDeferred.promise
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

          expectUncachedRequests('activities', 'attachments');
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
  });
})
;

