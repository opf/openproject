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
/* jshint expr: true */

describe.only('workPacakgeAttachmentsService', function() {
  var WorkPackageAttachmentsService, $httpBackend;

  // mock me a work package
  // TODO: remove that hyperagent.js nonsense asap
  var work_package = {
    props: {
      id: 1
    },
    links: {
      attachments: {
        url: function() {
          return '/api/v3/work_packages/1/attachments';
        }
      },
      addAttachment: {
        url: function() {
          return '/api/v3/work_packages/1/attachments';
        }
      }
    }
  }

  // mock me an attachment
  var attachment = {
    _links: {
      self: {
        href: '/attachments/1234'
      }
    }
  }

  beforeEach(module('openproject.workPackages'));

  beforeEach(inject(function(_WorkPackageAttachmentsService_, _$httpBackend_){
    WorkPackageAttachmentsService = _WorkPackageAttachmentsService_;
    $httpBackend = _$httpBackend_;
  }));

  afterEach(function() {
    $httpBackend.verifyNoOutstandingRequest();
    $httpBackend.verifyNoOutstandingExpectation();
  });

  describe('loading attachments', function() {
    beforeEach(function() {
      $httpBackend.expectGET('/api/v3/work_packages/1/attachments').respond({
        _embedded: {
          elements: [1,2,3]
        }
      });
    });

    it('should retrieve attachments for a given work pacakge', function () {
      WorkPackageAttachmentsService.load(work_package).then(function(result) {
        expect(result).to.eql([1,2,3]);
      });
      $httpBackend.flush();
    });
  });

  describe('creating an attachment', function() {
    beforeEach(function() {
      $httpBackend.expectPOST('/api/v3/work_packages/1/attachments').respond({});
    });

    it('should create an attachment for a given work package', function () {
      WorkPackageAttachmentsService.upload(work_package, attachment);
      $httpBackend.flush();
    });
  });

  describe('deleting an attachment', function() {
    beforeEach(function() {
      $httpBackend.expectDELETE('/attachments/1234').respond({});
    });

    it('should remove an attachment', function () {
      WorkPackageAttachmentsService.remove(attachment);
      $httpBackend.flush();
    });
  })

});
