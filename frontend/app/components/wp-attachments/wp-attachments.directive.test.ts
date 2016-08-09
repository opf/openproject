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
import {WorkPackageAttachmentsController} from './wp-attachments.directive';

describe('wp-attachments.directive', () => {
  var compile;
  var controller:WorkPackageAttachmentsController;
  var element;
  var $q;
  var rootScope;
  var scope;
  var isolatedScope;
  var workPackage = {
    id: 1234,
    attachments: {
      $load: () => {
        return $q.when({ elements: [] });
      },
      $unload: angular.noop,
      href: '/api/v3/work_packages/1/attachments',
    },
    activities: {
      $load: () => {
        return $q.when({ elements: [] });
      },
      $unload: angular.noop,
      href: '/api/v3/work_packages/1/activities',
    },
    updateLinkedResources: () => null,
    updateAttachments: () => null
  };

  beforeEach(angular.mock.module('openproject'));
  beforeEach(angular.mock.module('openproject.workPackages.directives'));
  beforeEach(angular.mock.module('openproject.templates'));

  var loadPromise,
    wpAttachments = {
      load: () => loadPromise,
      getCurrentAttachments: () => [],
      upload: angular.noop
    },
    apiPromise,
    configurationService = {
      api: () => apiPromise
    };

  beforeEach(angular.mock.module('openproject.workPackages.services', function ($provide) {
    $provide.constant('wpAttachments', wpAttachments);
  }));

  beforeEach(angular.mock.module('openproject.config', function ($provide) {
    $provide.constant('ConfigurationService', configurationService);
  }));

  beforeEach(angular.mock.inject(function ($rootScope, $compile, $httpBackend, _$q_) {
    $q = _$q_;
    apiPromise = $q.when('');
    loadPromise = $q.when([]);

    // Skip the work package cache update
    $httpBackend.expectGET('/api/v3/work_packages/1234').respond(200, {});

    var html = '<wp-attachments work-package="workPackage"></wp-attachments>';

    element = angular.element(html);
    rootScope = $rootScope;
    scope = $rootScope.$new();

    scope.workPackage = workPackage;

    compile = () => {
      $compile(element)(scope);
      scope.$digest();
    };
  }));

  describe('filterFiles', () => {
    beforeEach(() => {
      compile();
      isolatedScope = element.isolateScope();
      controller = element.controller('wpAttachments');
    });

    it('filters out attachments of type directory', () => {
      var files = [{type: 'directory'}, {type: 'file'}];

      controller.filterFiles(files);

      expect(files).to.eql([{type: 'file'}]);
    });
  });


  describe('uploadFilteredFiles', () => {
    var files = <File[]>[{type: 'directory'}, {type: 'file'}],
      dumbPromise = {
        then: call => call()
      };

    beforeEach(() => {
      compile();
      isolatedScope = element.isolateScope();
      controller = element.controller('wpAttachments');
    });

    it('triggers uploading of non directory files', () => {
      //need to have files to be able to trigger uploads
      controller.files = files;

      var uploadStub = wpAttachments.upload = sinon.stub().returns(dumbPromise);

      controller.uploadFilteredFiles(files);

      expect(uploadStub.calledWith(workPackage, [{type: 'file'}])).to.be.true;
    });
  });
});
