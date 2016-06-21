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
import {WorkPackageAttachmentsController} from './wp-attachments.directive'
type FileListAsArray = FileList & typeFixes.ArrayFix;

describe('WorkPackageAttachmentsDirective', function() {
  var compile;
  var controller: WorkPackageAttachmentsController;
  var element;
  var rootScope;
  var scope;
  var isolatedScope;
  var workPackage = {$links: {}};

  beforeEach(angular.mock.module('openproject.workPackages.directives'));
  beforeEach(angular.mock.module('openproject.templates'));

  var loadPromise,
    wpAttachments = {
      load: function() {
        return loadPromise;
      },
      getCurrentAttachments: function(){
        return [];
      },
      upload: angular.noop
    },
    apiPromise,
    configurationService = {
      api: function() {
        return apiPromise;
      }
    };

  beforeEach(angular.mock.module('openproject.workPackages.services', function($provide) {
    $provide.constant('wpAttachments', wpAttachments);
  }));

  beforeEach(angular.mock.module('openproject.config', function($provide) {
    $provide.constant('ConfigurationService', configurationService);
  }));

  beforeEach(angular.mock.inject(function($rootScope, $compile, $q) {
    apiPromise = $q(function(resolve) {
      return resolve('');
    });

    loadPromise = $q(function(resolve) {
      return resolve([]);
    });

    var html = '<wp-attachments edit work-package="workPackage"></wp-attachments>';

    element = angular.element(html);
    rootScope = $rootScope;
    scope = $rootScope.$new();

    scope.workPackage = workPackage;

    compile = function() {
      $compile(element)(scope);
      scope.$digest();
    };
  }));

  describe('filterFiles', function() {
    beforeEach(function() {
      compile();
      isolatedScope = element.isolateScope();
      controller = element.controller('wpAttachments');
    });

    it('filters out attachments of type directory', function() {
      var files = [{type: 'directory'}, {type: 'file'}];

      controller.filterFiles(<FileListAsArray> files);

      expect(files).to.eql([{type: 'file'}]);
    });
  });


  describe('uploadFilteredFiles', function() {
    var files = [{type: 'directory'}, {type: 'file'}],
      dumbPromise = {
        then: function(call) { return call(); }
      };

    beforeEach(function() {
      compile();
      isolatedScope = element.isolateScope();
      controller = element.controller('wpAttachments');
    });

    it('triggers uploading of non directory files', function() {
      //need to have files to be able to trigger uploads
      controller.files = files;

      var uploadStub = wpAttachments.upload = sinon.stub().returns(dumbPromise);

      controller.uploadFilteredFiles(<FileListAsArray> files);

      expect(uploadStub.calledWith(workPackage, [{type: 'file'}])).to.be.true;
    });
  });
});
