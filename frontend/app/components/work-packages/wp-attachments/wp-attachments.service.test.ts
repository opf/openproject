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

declare const WebKitBlobBuilder:any;

describe('wpAttachments service', () => {
  var $q;
  var wpAttachments;
  var $httpBackend;
  var wpNotificationsService;

  // mock me an attachment
  var attachment = {
    id: 1,
    _type: 'Attachment',
    href: '/api/v3/attachments/1'
  };

  var workPackage = {
    id: 1,
    $isHal: true,
    attachments: {
      $load: () => {
        return $q.when({ elements: [attachment] });
      },
      href: '/api/v3/work_packages/1/attachments',
    },
    activities: {
      $load: () => {
        return $q.when({ elements: [] });
      },
      href: '/api/v3/work_packages/1/activities',
    }
  };

  beforeEach(angular.mock.module('openproject'));
  beforeEach(angular.mock.module('openproject.workPackages'));

  beforeEach(angular.mock.inject((_wpAttachments_, _wpNotificationsService_, _$httpBackend_, _$q_) => {
    $q = _$q_;
    wpAttachments = _wpAttachments_;
    $httpBackend = _$httpBackend_;
    wpNotificationsService = _wpNotificationsService_
  }));

  afterEach(() => {
    $httpBackend.verifyNoOutstandingRequest();
    $httpBackend.verifyNoOutstandingExpectation();
  });

  describe('creating an attachment', () => {
    beforeEach(() => {
      $httpBackend.expectPOST('/api/v3/work_packages/1/attachments').respond({});
    });

    function createFiles() {
      var blob;
      try {
        var builder = new WebKitBlobBuilder();
        builder.append(['I am a TestFile for WebKit browsers']);
        blob = builder.getBlob();
      } catch(Error) {
        blob = new Blob(['I am a testfile']);
      }
      return [blob];
    }

    it('should create an attachment for a given work package', () => {
      var files = createFiles();
      wpAttachments.upload(workPackage, files);
      $httpBackend.flush();
    });
  });
});
